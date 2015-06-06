class LexemsController < ApplicationController

  def index
    # Входные параметры
    @translation = Translation.find(params[:translation_id])
    @src_from_form = @translation.inprogram
    @symbols =  Reservedsymbol.where(id: 1).first.symbols.lines
    @symbols = ArrToHash(@symbols)
    @keywords = Reservedkeyword.where(id: 1).first.keywords.lines
    @keywords = ArrToHash(@keywords)
    @strings_number=0
    # Выходные параметры
    @tabLex = [] # [лексема, тип, second index, порядковый номер]
    @tabNum = [] # [лексема, тип, порядковый номер]
    @tabVar = [] # [лексема, тип, порядковый номер]
    @tabStr = [] # [лексема, тип, порядковый номер]
    @tabErr = [] # [сообщение, текущее состояние, текущее значение индексной переменной]
    Lexer(@src_from_form, @keywords, @symbols)
    if !@tabErr.empty?
      if @tabErr[0][1] == 1
        @error = Error.new
        @error = Error.create(translation_id: @translation.id, discription: 'Неверное имя переменной в строке ', string_number: @strings_number+1)
        @translation.update_attributes(outprogram: "Ошибка: Неверное имя переменной")
      elsif @tabErr[0][1] == 2
        @error = Error.new
        @error = Error.create(translation_id: @translation.id, discription: 'Незакрытая строка в строке ', string_number: @strings_number+1)
        @translation.update_attributes(outprogram: "Ошибка: Незакрытая строка")
      elsif @tabErr[0][1] == 3
        @error = Error.new
        @error = Error.create(translation_id: @translation.id, discription: 'Недопустимый символ в строке ', string_number: @strings_number+1)
        @translation.update_attributes(outprogram: "Ошибка: Недопустимый символ")
      end
      redirect_to translation_path(@translation)
    else
      if !@tabLex.empty?
        @tabLex.each do |i|
        @lexem = Lexem.new
        @lexem = Lexem.create(translation_id: @translation.id, lexema: i[0], first_index: i[1], second_index: i[2], index_number: i[3])
        end
      end
      if !@tabVar.empty?
        @tabVar.each do |i|
        @variable = Variable.new
        @variable = Variable.create(translation_id: @translation.id, variable: i[0], first_index: i[1], second_index: i[2])
        end
      end
      if !@tabStr.empty?
        @tabStr.each do |i|
        @traslationstring = Translationstring.new
        @traslationstring = Translationstring.create(translation_id: @translation.id, translationstring: i[0], first_index: i[1], second_index: i[2])
        end
      end
      if !@tabNum.empty?
        @tabNum.each do |i|
        @number = Number.new
        @number = Number.create(translation_id: @translation.id, number: i[0], first_index: i[1], second_index: i[2])
        end
      end
      redirect_to translation_syntexes_path(@translation)
    end
  end

  def show
    @lexems=Lexem.where(translation_id: params[:translation_id]).each
    @variables=Variable.where(translation_id: params[:translation_id]).each
    @translationstrings=Translationstring.where(translation_id: params[:translation_id]).each
    @numbers=Number.where(translation_id: params[:translation_id]).each
    @errors=Error.where(translation_id: params[:translation_id]).each
  end

  def edit
    @error = Error.where(translation_id: params[:translation_id]).each
    @error.each do |i|
      i.destroy
    end
    @lexem = Lexem.where(translation_id: params[:translation_id]).each
    @lexem.each do |i|
      i.destroy
    end
    @variable = Variable.where(translation_id: params[:translation_id]).each
    @variable.each do |i|
      i.destroy
    end
    @traslationstring = Translationstring.where(translation_id: params[:translation_id]).each
    @traslationstring.each do |i|
      i.destroy
    end
    @number = Number.where(translation_id: params[:translation_id]).each
    @number.each do |i|
      i.destroy
    end
    redirect_to edit_translation_syntex_path(id: params[:id], translation_id: params[:translation_id])
  end

  #============================================================================
  # *************ОСНОВНОЙ АЛГОРИТМ**********************
  #============================================================================
  #
  #============================================================================
  # Лексический анализатор
  #============================================================================
  def Lexer(inSource, keyWords, tabSymbols) #, langGrammar)
  	ind  = 0        # Индекс текущего символа
    csym = ''       # Текущий символ
    @state= 0       # состояние:
                    # 	0 - начальное состояние
                    # 	1 - число
                    # 	2 - строка
                    # 	3 - идентификатор
                    #   4 - символы    
    while not csym.nil?
      csym = inSource[ind]
      if isNumber(csym)
        ind = digitHandling(inSource, ind)
      elsif isApostrophe(csym)
        ind = cstrHandling(inSource, ind)
      elsif isReservedSym(csym)
      	ind = symHandling(inSource, ind)
      else
        ind = idntHandling(inSource, ind)
      end
      if @state > 0
      	errow = ["error", @state, ind]
      	addToTable(errow,@tabErr)
      	return
      end
      ind += 1
    end
  end
  #============================================================================
  # ***************ВЕТВИ ОСНОВНОГО АЛГОРИТМА*****************
  #============================================================================
  #
  #============================================================================
  # Обработка цифры
  #============================================================================
  def digitHandling(strInput, inIndx)
    @state   = 1                    # состояние обработки числа
    lexem   = ""                    # Лексема
    type    = 40                    # целочисленная константа
    sym     = strInput[inIndx]
    while isNumber(sym)
      lexem  += sym
      inIndx += 1
      sym     =  strInput[inIndx]
    end
    if isReservedSym(sym) or isWhiteSpace(sym) or sym.nil?
    	inIndx -= 1
    	toConstAndLexTab(lexem, type, @tabNum)
		@state = 0                    # начальное состояние
	end
    return inIndx
  end
  #============================================================================
  # Обработка строк
  #============================================================================
  def cstrHandling(strInput, inIndx)
    @state   = 2                    # состояние обработки строки
    lexem   = ""                    # Лексема
    type    = 41                    # строковая константа
    endstr  = 0                     # флаг окончания строковой константы
    inIndx += 1                     # Переместимся на один символ вперёд
    sym     = strInput[inIndx]
    while nextStep(sym, endstr)
    	if isApostrophe(sym)
    		endstr  = 1
    	else
    		lexem  += sym
      		inIndx += 1
      		sym     =  strInput[inIndx]
    	end
    end
    if endstr == 1
    	toConstAndLexTab(lexem, type, @tabStr)
		@state = 0                    # начальное состояние
	end
    return inIndx    
  end
  #============================================================================
  # Следующая итерация
  #============================================================================
  def nextStep(sym, endstr)
  	if endstr == 1
  		return false
  	end
  	if sym.nil?
  		return false
  	end
  	return true
  end
  #============================================================================
  # Обработка идентификаторов
  #============================================================================
  def idntHandling(strInput, inIndx)
    @state  = 3                     # состояние обработки идентификатора
    lexem   = ""                    # Лексема
    type    = 30                    # идентификатор
    endstr  = 0                     # флаг окончания идентификатора
    sym     = strInput[inIndx]
    if isWhiteSpace(sym)
    	@state = 0
    	return inIndx
    end
    while (not sym.nil?) and (endstr == 0)
    	if isApostrophe(sym) or isWhiteSpace(sym) or isReservedSym(sym)
    		endstr  = 1
    	elsif /\w/=~sym
    		  lexem  += sym
      		inIndx += 1
      		sym     =  strInput[inIndx]
      else 
        return @state
      end
    end
    if endstr == 1 or sym.nil?
    	inIndx -= 1
    	if lexem.size > 0
    		toConstAndLexTab(lexem, type, @tabVar)
    	end
		@state = 0                    # начальное состояние
	end
    return inIndx    
  end
  #============================================================================
  # Обработка зарезервированных символов
  #============================================================================
  def symHandling(strInput, inIndx)
    @state   = 4                     # состояние обработки идентификатора
    lexem   = ""                     # Лексема
    endstr  = 0  
	sym     = strInput[inIndx]
    while (not sym.nil?) and (endstr == 0)
    	if not isReservedSym(sym)
    		endstr  = 1
    	else
    		if lexem == ""
    			lexem  += sym
      	else
      		if isReservedSym(lexem+sym)
      			lexem  += sym
      		else
      			toConstAndLexTab(lexem, nil, nil)      			
      			lexem   = sym      				
      		end
      	end
      	inIndx += 1
      		sym     =  strInput[inIndx]
    	end
    end	
    if (endstr == 1 or sym.nil?) and isReservedSym(lexem)
    	inIndx -= 1
    	toConstAndLexTab(lexem, nil, nil)
		@state = 0                    # начальное состояние
	end
    return inIndx   
  end
  #============================================================================
  # ****************СЛУЖЕБНЫЕ ФУНКЦИИ*********************
  #============================================================================
  # 
  #============================================================================
  # Преобразует входной массив, вида:
  # arr[ind]="val1|val2|val3"
  # в хеш вида:
  # hash[val1]=[val2, val3]
  #============================================================================
  def ArrToHash(inArray)
    hash = {}
    ind  = 0
    while str = inArray.at(ind)
      if str.index("\r\n") 
        str = str.chop
      end
      if str.index("\t") 
        str = str.chop
      end
      arr=str.split("|")
      key=arr[0]
      arr.delete_at(0)
      hash[key]=arr
      ind += 1
    end
    return hash
  end
  #============================================================================
  # Проверка существования лексемы в таблице
  #============================================================================
  def chckLexInTable(inLexem, arrTab)
    ind  = 0
    cnt  = 0
    while arr = arrTab.at(ind) 
      if arr[0] == inLexem
        return true
      end
      ind += 1
    end
    return false
  end
  #============================================================================
  # Проверка существования лексемы в таблице
  #============================================================================
  def getLexNumInTable(inLexem, lexType, arrTab)
    ind  = 0
    while arr = arrTab.at(ind) 
      if (arr[0] == inLexem)
        return arr[2]
      end
      ind += 1
    end
    return 0
  end
  #============================================================================
  # Добавление в таблицу
  #============================================================================
  def addToTable(arrRow,tabName)
    len = tabName.length
    len += 1
    arrRow.push(len)
    tabName.push(arrRow)
    return len
  end
  #============================================================================
  # Запись в таблицу целочисл. и лексем
  #============================================================================
  def toConstAndLexTab(inLexem, inType, tabConst)
  	row     = [inLexem]
  	
  	tabname = nil
    if isReservedSym(inLexem)
     	tabname = @symbols
    elsif isReservedWord(inLexem.downcase)
      inLexem = inLexem.downcase
    	tabname = @keywords 
    end

    if tabname.nil?
    	row.push(inType)
    	if not chckLexInTable(inLexem, tabConst)
    		addToTable(row,tabConst)
	    else
    		cnt = getLexNumInTable(inLexem, inType, tabConst)
    		row.push(cnt)
    	end
    else 
    	type = getValByKey(inLexem, tabname, 0)
    	secindx = getValByKey(inLexem, tabname, 1)
    	row.push(type)
    	row.push(secindx)
    end
    copyrow  = Array.new(row)
    addToTable(copyrow,@tabLex)
  end
  #============================================================================
  # Вернуть значение по ключу из нужной позиции
  #============================================================================
  def getValByKey(inLexem, inTab, pos)
    if inLexem.nil? or inTab.nil?
      return nil
    end
    if pos.nil?
    	pos=0
    end
    val     = inTab[inLexem]
    if val.nil?
    	return nil
    end
    return val[pos]
  end
  #============================================================================
  # ** Функции с различными проверками **
  #============================================================================
  #
  #============================================================================
  # Является ли символ цифрой
  #============================================================================
  def isNumber(inSymbol)
    if inSymbol.nil? 
      return false
    end
    dgtcnt  = inSymbol.scan(/[0-9]/).size
    strsize = inSymbol.size
    result  = false
    if (dgtcnt > 0) & (dgtcnt == strsize) 
        result = true
    end
    result
  end
  #============================================================================
  # Проверка апострофа
  #============================================================================
  def isApostrophe(inSymbol)
    if inSymbol.nil? 
      return false
    end
    cnt     = inSymbol.scan(/[\']/).size
    strsize = inSymbol.size
    result  = false
    if (cnt > 0) & (cnt == strsize) 
        result = true
    end
    result
  end
  #============================================================================
  # Проверка латинских букв
  #============================================================================
  def isLetter(inSymbol)
    if inSymbol.nil? 
      return false
    end
    cnt     = inSymbol.scan(/[A-z]/).size
    strsize = inSymbol.size
    result  = false
    if (cnt > 0) & (cnt == strsize) 
        result = true
    end
    result
  end
  #============================================================================
  # Проверка зарезервированных символов
  #============================================================================
  def isReservedSym(inSymbol)
    if inSymbol.nil? 
      return false
    end
    val     = @symbols[inSymbol]
    return (not val.nil?)
  end
  #============================================================================
  # Проверка зарезервированных слов
  #============================================================================
  def isReservedWord(inLexem)
    if inLexem.nil? 
      return false
    end
    val     = @keywords[inLexem]
    return (not val.nil?)
  end
  #============================================================================
  # Все неотображаемые символы считать пробелом
  #============================================================================
  def isWhiteSpace(inSymbol)
    if inSymbol.nil? 
      return false
    end
    if inSymbol == "\n"
      @strings_number+=1
    end
    return inSymbol.ord < 33
  end
  #============================================================================
end