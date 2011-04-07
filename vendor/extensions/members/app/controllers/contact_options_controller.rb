class ContactOptionsController < ApplicationController
	def destroy
		co = ContactOption.find(params[:id])
		co.destroy if co.person.user == current_user
		render :text => "destroyed"
	end
end

