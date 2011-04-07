class Admin::PageAttachmentsController < ApplicationController
  
  def index
    @attachments = PageAttachment.paginate :per_page => 25, :page => params[:page], :conditions => {:parent_id => nil}, :order => 'title, filename'
  end
  def grid
    @attachments = PageAttachment.paginate :per_page => 25, :page => params[:page], :conditions => {:parent_id => nil}, :order => 'title, filename'
  end
  
  def edit
    @page_attachment = PageAttachment.find(params[:id])
  end

  #TODO: modified by MTL -- debugging.  Seems to be an issue.
  def update
    @page_attachment = PageAttachment.find(params[:id])
    title = params[:page_attachment][:title]
    if @page_attachment.update_attributes(params[:page_attachment])
      @page_attachment.title = title
      @page_attachment.save
      Rails.logger.info @page_attachment.inspect
      redirect_to admin_page_attachments_url
    else
      render :edit
    end
  end
  
	def move_higher
		if request.post?
			@attachment = PageAttachment.find(params[:id])
			@attachment.move_higher
			render :partial => 'admin/page/attachment', :layout => false, :collection => @attachment.page.attachments
		end
	end

	def move_lower
		if request.post?
			@attachment = PageAttachment.find(params[:id])
			@attachment.move_lower
			render :partial => 'admin/page/attachment', :layout => false, :collection => @attachment.page.attachments
		end
	end
	
	def destroy
		if request.post?
			@attachment = PageAttachment.find(params[:id])
			page = @attachment.page
			@attachment.destroy
			render :partial => 'admin/page/attachment', :layout => false, :collection => page.attachments
		end
	end
end