class PagesController < ApplicationController

  before_filter :login_required_admin, :only => [ :index, :new, :create, :update, :edit, :destroy ]
  def index
    @pages=Page.find(:all, :order => "url")    
  end
  def login_required_admin
    if !authorized? or self.current_team.login != "admin" then
       access_denied
    end
  end
  def new

  end

  def create

    @page = Page.new(params[:page])
    if @page.save
      flash[:notice] = "Страница добавлена"
      redirect_to "/page/" + @page.url
    else
      render :action => 'new'
    end    
  end

  def edit
    @page=Page.find(params[:id])
  end

  def update
    @page=Page.find(params[:id])

    if @page.update_attributes(params[:page])

      flash[:notice] = "Страница обновлена"
      redirect_to "/page/" + @page.url
    else
      render :action => 'new'
    end
  end

  def destroy
    @page=Page.find(params[:id])
    @page.destroy
    flash[:notice] = "Страница удалена"
    redirect_to :action => "index"
  end

  def show
    @page=Page.find_by_url(params[:path].join('/'))  
    
  end

end
