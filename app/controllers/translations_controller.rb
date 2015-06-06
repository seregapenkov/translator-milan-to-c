class TranslationsController < ApplicationController
	def index
		@translations = Translation.all 
	end

	def show
		unless @translation = Translation.where(id: params[:id]).first
		render_404
		end
	end

	def new
		@translation = Translation.new
	end

	def edit
		@translation = Translation.find(params[:id])
	end

	def create
		@translation = Translation.create(translation_params)
		if @translation.errors.empty?
			redirect_to translation_lexems_path(@translation)
		else 
			flash.now[:error] = "Вы не заполнили обязательные поля!"
			render "new"
		end
	end

	def update
		@translation = Translation.find(params[:id])
		@translation.update_attributes(translation_params)
		if @translation.errors.empty?
			redirect_to edit_translation_lexem_path(id: @translation.id, translation_id: @translation.id)
		else 
			flash.now[:error] = "Вы не заполнили обязательные поля!"
			render "edit"
		end
	end

	def destroy
		@translation = Translation.find(params[:id])
		@lexem = Lexem.where(translation_id: @translation.id).each
		@rule = Syntex.where(translation_id: @translation.id).each
		@translation.destroy
		@lexem.each do |i|
			i.destroy		
		end
		@rule.each do |i|
			i.destroy		
		end
		redirect_to action: "index"
	end

	private

		def translation_params
			params.require(:translation).permit(:name, :inprogram)
		end 
end
