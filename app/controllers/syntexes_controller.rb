class SyntexesController < ApplicationController

	def index
		@translation = Translation.find(params[:translation_id])
		# Выходные параметры
		@currentLex=1
		@rules = []
		@outprogram=""
		@Error=[]
		@Declare=[]
		@TypeS=[]
		@TypeI=[]
		@countV=0
		@typeExp=0

		Program()	

	  if !@Error.empty?
        @error = Error.new
        @error = Error.create(translation_id: @translation.id, discription: @Error[0])
        @translation.update_attributes(outprogram: @Error[0])
      else
      	if !@rules.empty?
        	@rules.each do |i|
        	@rule = Syntex.new
        	@rule = Syntex.create(translation_id: @translation.id, rule: i)
        	@translation.update_attributes(outprogram: @outprogram)
    		end
      	end
      end
      redirect_to translation_path(@translation)
  	end

  	def show
  		@errors=Error.where(translation_id: params[:translation_id]).each
    	@rules=Syntex.where(translation_id: params[:translation_id]).each
  	end

  	def edit
    	@error = Error.where(translation_id: params[:translation_id]).each
    	@error.each do |i|
      		i.destroy
    	end
    	@rule = Syntex.where(translation_id: params[:translation_id]).each
    	@rule.each do |i|
    		i.destroy
    	end
    	redirect_to translation_lexems_path(translation_id: params[:translation_id])
	end	

	def Program()
    @rules<<"<программа>-><объявление переменных><тело программы>"
    @outprogram<<"#include <stdio.h>"<<"\n"<<"int main()"<<"\n"<<"{"<<"\n"
    if Declaration()
      if ProgramBox()
        @outprogram<<"\n"<<"return 0;"<<"\n"<<"}"
        return true
      else 
        return false
      end
    else 
      return false
    end 
  end

  def Declaration()
    if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema.downcase=="var"
      @rules<<"<объявление переменных>->var<список переменных>"
      @currentLex+=1
      if VarList()
        @outprogram<<"\n"
        return true
      else 
        return false
      end
    else
      @Error<<"Следующая лексема должна быть 'var'"
      return false
    end
  end

  def VarList()
    @rules<<"<список переменных>-><блок переменных>;<другой список переменных>"
    if Varbox()
      if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema==";"
        @outprogram<<"\n"
        if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema.downcase=="begin"
          return true
        end
        @currentLex+=1
        if spisok()
          return true
        else
          return false
        end
      else
        @Error<<"Следущая лексема должна быть ';'"
        return false
      end
    end
    return false
  end

  def Varbox()
    @rules<<"<блок переменных>-><список имен>:<тип>"
    pos=@outprogram.size
    if Namelist()
      @outprogram<<";"
      if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema==":"
        @currentLex+=1
        if Type()
          if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex-1).first.lexema.downcase=="integer"
            @outprogram.insert(pos, "int ")
          elsif Lexem.where(translation_id: params[:translation_id], index_number: @currentLex-1).first.lexema.downcase=="string"
            @outprogram.insert(pos, "string ")
          end
          @outprogram<<"\n"
          return true
        else 
          return false
        end
      else 
        @Error<<"Следущая лексема должна быть ':'"
        return false
      end
    else 
      return false
    end
  end

  def spisok()
    if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema.downcase=="begin"
      @rules<<"<другой список переменных>-><список переменных>"
      return true
    else
      @rules<<"<другой список переменных>->пусто"
    end
    if VarList() 
      return true
    end
  end

  def Namelist()
    if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.first_index==30
      @outprogram<<Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema
      @rules<<"<список имен>->"+Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema+"<другой список имен>"
      if @Declare.include?(Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema)
        @Error<<"Семантическая ошибка: Эта переменная была объявлена ​​ранее"
      end
      @Declare<<Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema
      @currentLex+=1
      @countV+=1
      if NameSp()
        return true
      else
        return false
      end
    else
      return false
    end
  end

  def NameSp()
    if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema==","
      @outprogram<<", "
      @rules<<"<другой список имен>->,<список имен>"
      @currentLex+=1
      if Namelist()
        return true
      else 
        return false
      end
    else
      @rules<<"<другой список имен>->пусто"
      return true
    end
  end
  
  def Type()
    if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema=="integer"
      setTypeI(@countV)
      @rules<<"<Тип>->integer"
      @countV=0
      @currentLex+=1
      return true
    elsif 
      Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema.downcase=="string"
      setTypeS(@countV)
      @rules<<"<Тип>->string"
      @countV=0
      @currentLex+=1
      return true
    else 
      @Error<<"Неверный тип"
      return false
    end
  end

  def setTypeI(n)
    for i in (@Declare.count-1).downto(@Declare.count-n)
      if !@TypeS.include?(@Declare[i])
        @TypeI<<@Declare[i]
      else 
        @Error<<"Семантическая ошибка: Эта переменная имеет неправильный тип"
      end
    end
  end

  def setTypeS(s)
    for i in (@Declare.count-1).downto(@Declare.count-s)
      if !@TypeI.include?(@Declare[i])
        @TypeS<<@Declare[i]
      else 
        @Error<<"Семантическая ошибка: Эта переменная имеет неправильный тип"
      end
    end
  end

  #------------------------------------------------------#
  #------------------------------------------------------#
  #------------------------------------------------------#

  def ProgramBox()
    if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema.downcase=="begin"
      @rules<<"<тело программы>->begin <последовательность операторов> end."
      @currentLex+=1
      if OperatorSequence()
        if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema.downcase=="end"
          @currentLex+=1
          if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema=="."
            @currentLex+=1
            return true
          else 
            @Error<<"Следующая лексема должна быть '.'"
            return false
          end
        else 
          @Error<<"Следующая лексема должна быть 'end'"
          return false
        end
      else 
        return false
      end
    else 
      @Error<<"Следующая лексема должна быть 'begin'"
      return false
    end
  end

  def OperatorSequence()
    #@rules<<"<последовательность операторов>-><оператор><другая послед. операторов>"
    if Operator()
      if Rest1()
        return true
      else 
        return false
      end
    else 
      return false
    end
  end

  def Rest1()
    if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema==";"
      @currentLex+=1
      if OperatorSequence()
        #@rules<<"<другая послед. операторов>->;<последовательность операторов>"
        return true
      else 
        #@rules<<"<другая послед. операторов>->;"
        return true
      end
    else 
      @rules<<"<другая послед. операторов>->пусто"
      return true
    end
  end

  def Operator()
    if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.first_index==30
      @outprogram<<Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema
      type=CheckItem()
      @rules<<"<оператор>->"+Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema+":=<выражение>"
      @currentLex+=1
      if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema==":="
        @outprogram<<"="
        @currentLex+=1
        if Expression()
          @outprogram<<";"<<"\n"
          if type!=@typeExp
            @Error<<"Семантическая ошибка: несоответствие типов"
          end
          return true
        else 
          return false
        end
      else 
        @Error<<"Следующая лексема должна быть ':='"
        return false
      end
    elsif Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema.downcase=="if"
      @outprogram<<"if("
      @currentLex+=1
      @rules<<"<оператор>->if <условие> then <оператор><иначе, оператор>"
      if Condition()
        if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema.downcase=="then"
          @outprogram<<")"<<"\n"
          @currentLex+=1
          if Operator()
            if elseOp()
              return true
            else 
              return false
            end
          else 
            return false
          end
        else 
          @Error<<"Следующая лексема должна быть 'then'"
          return false
        end
      else 
        return false
      end
    elsif Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema.downcase=="while"
      @outprogram<<"while("
      @currentLex+=1
      @rules<<"<оператор>->while <условие> do <оператор>"
      if Condition()
        @outprogram<<") "
        if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema.downcase=="do"
          @currentLex+=1
          if Operator()
            @outprogram<<"\n"
            return true
          else 
            reurn false
          end
        else 
          @Error<<"Следующая лексема должна быть 'do'"
          return false
        end
      else 
        return false
      end 
    elsif Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema.downcase=="for"
      @outprogram<<"for("
      @currentLex+=1
      @rules<<"<оператор>->for "+Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema+":= <выражение> to <выражение> do <оператор>"
      if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.first_index==30
        @outprogram<<Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema.downcase
        id = @currentLex
        @currentLex+=1
        if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema==":="
          @outprogram<<"="
          @currentLex+=1
          if Expression()
            @outprogram<<";"
            if @typeExp!=3
              @Error<<"Семантическая ошибка: Выражение в цикле должно быть целого типа"
            end
            if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema.downcase=="to"
              @outprogram<<Lexem.where(translation_id: params[:translation_id], index_number: id).first.lexema.downcase<<"<"
              @currentLex+=1
              if Expression()
                @outprogram<<";++"<<Lexem.where(translation_id: params[:translation_id], index_number: id).first.lexema.downcase
                if @typeExp!=3
                  @Error<<"Семантическая ошибка: Выражение в цикле должно быть целого типа"
                end
                if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema.downcase=="do"
                  @outprogram<<")"<<"\n"
                  @currentLex+=1
                  if Operator()
                    @outprogram<<"\n"
                    return true
                  else 
                    return false
                  end
                else 
                  @Error<<"Следующая лексема должна быть 'do'"
                  return false
                end
              else 
                return false
              end
            else 
               @Error<<"Следующая лексема должна быть 'to'"
               return false
             end
           else 
            return false
          end
        else 
          @Error<<"Следующая лексема должна быть ':='"
          return false
        end
      else
        @Error<<"Следующая лексема должна быть 'ид.'"
        return false
      end
    elsif Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema.downcase=="write"
      @outprogram<<"printf(\"" 
      @currentLex+=1
      @rules<<"<оператор>-> write( <выражение> )"
      if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema=="("
        @currentLex+=1
        if Expression()
          if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema==")"
            @outprogram<<"\");\n"
            @currentLex+=1
            return true
          else 
            @Error<<"Следующая лексема должна быть ')'"
            return false
          end 
        else
          return false
        end
      else
        @error<<"Следующая лексема должна быть '('"
        return false
      end
    elsif Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema.downcase=="read"
      @outprogram<<"scanf"
      @currentLex+=1
      @rules<<"<оператор>->read( "+Lexem.where(translation_id: params[:translation_id], index_number: @currentLex+1).first.lexema+" )"
      if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema.downcase=="("
        @outprogram<<"("
        @currentLex+=1
        if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.first_index==30
          item=CheckItem()
          if item == 3
            @outprogram<<"\"%d\",&"
          else 
            @outprogram<<"\"%s\",&"
          end
          @outprogram<<Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema
          @currentLex+=1
          if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema==")"
            @outprogram<<");\n"
            @currentLex+=1
            return true
          else 
            @Error<<"Следующая лексема должна быть ')'"
            return false
          end
        else 
          @Error<<"Следующая лексема должна быть 'ид.'"
          return false
        end
      else 
        @Error<<"Следующая лексема должна быть '('"
        return false
      end
    elsif Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema.downcase=="begin"
      @outprogram<<"{\n"
      @currentLex+=1
      @rules<<"<оператор>->begin <последовательность операторов> end"
      if OperatorSequence()
        if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema.downcase=="end"
          @outprogram<<"}\n"
          @currentLex+=1
          return true
        else 
          @Error<<"Следующая лексема должна быть 'end'"
          return false
        end
      else
        @Error<<"Следующая лексема должна быть 'ид.' или 'if' или 'while' или 'for' или 'write' или 'begin' или 'read'"
        return false
      end
    end
  end

  def elseOp()
    if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema.downcase=="else"
      @outprogram<<"else\n"
      @currentLex+=1
      @rules<<"<иначе, оператор>->else <оператор>"
      if Operator()
        return true
      end
    else 
      @rules<<"<иначе, оператор>->пусто"
      return true
    end
  end

  def Condition()
    if Comparison()
      @rules<<"<условие>-><сравнение><логический оператор, сравнение>"
      if logOpCon()
        return true
      else
        return false
      end
    else 
      return false
    end
  end

  def logOpCon()
    if LogicOperator()
      @rules<<"<логический оператор, сравнение>-><логический оператор><сравнение>" 
      if Condition()
        return true
      else 
        return false
      end 
    else 
      @rules<<"<логический оператор, сравнение>->пусто"
      return true
    end
  end

  def Comparison()
    if Expression()
      @rules<<"<сравнение>-><выражение> отношение <выражение>"
      type1=@typeExp
      @typeExp=0
      if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.first_index==21
        @outprogram<<Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema.downcase
        @currentLex+=1
        if Expression()
          type2=@typeExp
          @typeExp=0
          if type1!=type2
            @Error<<"Семантическая ошибка: Сравнение не может быть сделано с различными типами"
          end
          return true
        else 
          return false
        end
      else
        @Error<<"Следующая лексема должна быть '=' или '<>' или '<' или '>' или '<=' или '>='"
        return false
      end
    else 
      return false
    end
  end

  def LogicOperator()
    if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema.downcase=="and"
      @outprogram<<" && "
      @currentLex+=1
      @rules<<"<логический оператор>->и"
      return true
    elsif Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema.downcase=="or"
      @outprogram<<" || "
      @currentLex+=1
      @rules<<"<логический оператор>->или"
      return true
    else
      return false
    end
  end

  def CheckItem()
    if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.first_index==40
      return 3
    elsif Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.first_index==41
      return 4
    elsif Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.first_index==30
      if @TypeI.include?(Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema)
        return 3
      elsif @TypeS.include?(Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema)
        return 4
      else
        @Error<<"Семантическая ошибка: Эта переменная не была объявлена"
      end
    end  
  end

  def Expression()
    item=CheckItem()
    if item==3
      if NumExpression()
        @typeExp=3
        @rules<<"<выражение>-><числ. выражение>"
        return true
      end
    elsif item == 4
      if StrExpression()
        @typeExp=4
        @rules<<"<выражение>-><стр. выражение>"
        return true
      end
    else
      @Error<<"Следующая лексема должна быть 'стр. конст.' или 'цел. конст.'"
      return false
    end
  end

  def NumExpression()
    if Term()
      @rules<<"<числ. выражение>-><терминал><+-числ. выражение>"
      if NumRest()
        return true
      else 
        return false
      end
    else 
      return false
    end
  end

  def NumRest()
    if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema=="+"
      @outprogram<<Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema
      @currentLex+=1
      @rules<<"<+-числ. выражение>->+<числ. выражение>"
      if NumExpression()
        return true
      else 
        return false
      end
    elsif Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema=="-"
      @outprogram<<Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema
      @currentLex+=1
      @rules<<"<+-числ. выражение>->-<числ. выражение>"
      if NumExpression()
        return true
      else 
        return false
      end
    else
      @rules<<"<+-числ. выражение>->пусто"
      return true
    end
  end

  def Term()
    if Multiplier()
      @rules<<"<терминал>-><множитель><другой терминал>"
      if termRest()
        return true
      else 
        return false
      end
    else 
      return false
    end
  end

  def termRest()
    if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema=="*"
      @outprogram<<Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema
      @currentLex+=1
      @rules<<"<другой терминал>->*<числ. выражение>"
      if NumExpression()
        return true
      else 
        return false
      end
    elsif Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema=="/"
      @outprogram<<"/"
      @currentLex+=1
      @rules<<"<другой терминал>->/<числ. выражение>"
      if NumExpression()
        return true
      else 
        return false
      end
    else 
      @rules<<"<другой терминал>->пусто"
      return true
    end
  end

  def Multiplier()
    if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.first_index==30 && CheckItem()==3
      @outprogram<<Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema
      @typeExp=3
      @currentLex+=1
      @rules<<"<множитель>->"+Lexem.where(translation_id: params[:translation_id], index_number: @currentLex-1).first.lexema
      return true
    elsif Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.first_index==40
      @outprogram<<Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema
      @typeExp=3
      @currentLex+=1
      @rules<<"<множитель>->"+Lexem.where(translation_id: params[:translation_id], index_number: @currentLex-1).first.lexema
      return true
    elsif Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema=="("
      @outprogram<<Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema
      @currentLex+=1
      @rules<<"<множитель>->( <числ. выражение> )"
      if NumExpression()
        if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema==")"
          @outprogram<<Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema
          @currentLex+=1
          return true
        else
          @Error<<"Следующая лексема должна быть ')'"
          return false
        end
      else
        return false
      end
    else
      @Error<<"Семантическая ошибка: Следующая лексема должна быть целого типа"
      return false
    end
  end

  def StrExpression()
    if StrTerm()
      @rules<<"<стр. выражение>-><стр. терминал><другое стр. выражение>" 
      if strRest()
        return true
      else
        return false
      end
    else
      return false
    end    
  end

  def strRest()
    if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema=="+"
      @outprogram<<Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema
      @currentLex+=1
      @rules<<"<другое стр. выражение>->+<стр. выражение>"
      if StrExpression()
        return true
      else 
        return false
      end
    else 
      @rules<<"<другое стр. выражение>->пусто"
      return true
    end
  end

  def StrTerm()
    if CheckItem()==4
      @typeExp=4
      if Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.first_index==30
        @outprogram<<Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema
        @currentLex+=1
        @rules<<"<стр. терминал>->"+Lexem.where(translation_id: params[:translation_id], index_number: @currentLex-1).first.lexema
        return true
      elsif Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.first_index==41
        @outprogram<<"\""<<Lexem.where(translation_id: params[:translation_id], index_number: @currentLex).first.lexema<<"\""
        @currentLex+=1
        @rules<<"<стр. терминал>->"+Lexem.where(translation_id: params[:translation_id], index_number: @currentLex-1).first.lexema
        return true
      end
    else
      @Error<<"Семантическая ошибка: Следующий лексема должна быть строкового типа"
      @typeExp=3
      return false
    end    
  end
end