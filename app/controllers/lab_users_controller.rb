class LabUsersController < ApplicationController
  #restricted to admins 
  before_filter :authorise_as_manager, :except=>[:progress]
  #redirect to index view when trying to see unexisting things
  before_filter :save_from_nil, :only=>[:edit]
  before_filter :manager_tab
  def save_from_nil
    @lab_user = LabUser.find_by_id(params[:id])
    if @lab_user==nil 
      redirect_to(lab_users_path,:notice=>"invalid id.")
    end
  end

  
  # GET /lab_users
  # GET /lab_users.xml
  #index and new view are merged
  def index
    #@lab_users = LabUser.find(:all, :order=>params[:sort_by])
    if params[:dir]=="asc" then
      dir = "ASC"
      @dir = "desc"
    else 
      dir = "DESC"
      @dir = "asc"
    end
    order = params[:sort_by]!=nil ? "#{params[:sort_by]} #{dir}" : "" 
    @lab_users = LabUser.order(order).paginate(:page => params[:page], :per_page => 10)
    @lab_user = LabUser.new
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lab_users }
    end
  end
  

  # GET /lab_users/1/edit
  def edit
    #@lab_user = LabUser.find(params[:id])
  end

  # POST /lab_users
  # POST /lab_users.xml
  def create
    if params[:dir]=="asc" then
      dir = "ASC"
      @dir = "&dir=desc"
    else 
      dir = "DESC"
      @dir = "&dir=asc"
    end
    @lab_users = LabUser.find(:all).order("#{params[:sort_by]} #{dir}")
    # logic for when adding/removing multiple users at once to a specific lab
    if params[:lab_user][:page]=='bulk_add' then
      all_users=User.all
      checked_users=get_users_from(params[:users])
      removed_users=all_users-checked_users
      lab=params[:lab_user][:lab_id]
      
      checked_users.each do |c|
        l=LabUser.new
        l.lab_id=lab
        l.user_id=c.id
        #if there is no db row with the se parameters then create one
        if LabUser.find(:first, :conditions=>["lab_id=? and user_id=?", lab, c.id])==nil then
          l.save
        end
      end
      removed_users.each do |d|
        #look for the unchecked users and remove them from db if they were there
        l=LabUser.find(:first, :conditions=>["lab_id=? and user_id=?", lab, d.id])
        l.delete if l!=nil
      end
      redirect_to(lab_users_path, :notice => 'successful update.')
    else
      #adding a single user to a lab
      @lab_user = LabUser.new(params[:lab_user])
      respond_to do |format|
        if @lab_user.save
        format.html { redirect_to(lab_users_path, :notice => 'successful update.') }
        format.xml  { render :xml => @lab_user, :status => :created, :location => @lab_user }
      else
        format.html { render :action => "index" }
        format.xml  { render :xml => @lab_user.errors, :status => :unprocessable_entity}
      end #end if
    end #end respond_to
  end #end else
end

  # PUT /lab_users/1
  # PUT /lab_users/1.xml
  def update
    @lab_user = LabUser.find(params[:id])
    
    respond_to do |format|
      if @lab_user.update_attributes(params[:lab_user])
        format.html { redirect_to(lab_users_path, :notice => 'successful update.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lab_user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lab_users/1
  # DELETE /lab_users/1.xml
  def destroy
    @lab_user = LabUser.find(params[:id])
    #when removing someone from a lab, you need to thow their machines away too
    @lab_user.lab.lab_vmts.each do |template|
      vm=Vm.find(:first, :conditions=>["lab_vmt_id=? and user_id=?", template.id, @lab_user.user.id ])
      vm.destroy if vm!=nil
    end
    
    @lab_user.destroy

    respond_to do |format|
      format.html { redirect_to(lab_users_path) }
      format.xml  { head :ok }
    end
  end
  
  #view for adding multiple users to a lab
  def add_users
    @lab_users = LabUser.all
    @lab_user = LabUser.new 
    #if no lab is set, take the first
    @lab=Lab.find_by_id(params[:id])
    if @lab==nil then
      @lab=Lab.first
      redirect_to(add_users_path) if params[:id]!=nil
    end
    #users already in the particular lab
    @users_in=[]
    @lab.lab_users.each do |u|
      @users_in<<u.user
    end
  end
  
  def import
    @lab=Lab.find_by_id(params[:lab_id])
    if (params[:txtsbs].present? && @lab!=nil)
      @upload_text = params[:txtsbs].read
      users=@upload_text.split('\n')
      
      notice=""
      @upload_text.each_line do |u| 
        
      #users.each do |u|
      #while u = params[:txtsbs].readline        
        u.chomp!
        user=u.split(',')#username,realname, email, token
        @user=User.find(:first, :conditions=>["username=?", user[0]])
        if (@user==nil) then #user doesnt exist
          email=user[2]
          email=user[0]+"@itcollege.ee" if email!=nil

          @user=User.create!(:email=>email ,:username=>user[0], :name=>user[1] ,:password=>user[3], :authentication_token=>user[3])
        end
        #TODO do we update the existing user? to add a token for example?
        labuser=LabUser.find(:first, :conditions=>["user_id=? and lab_id=?", @user.id, @lab.id])
        # by now we surely have a user, add it to the lab
        if labuser==nil then
          labuser=LabUser.new
          labuser.lab=@lab
          labuser.user=@user
          if labuser.save 
            notice=notice+user[0]+" added successfully<br/>"
          else
            notice=notice+user[0]+" adding failed<br/>"
          end
        else
          notice=notice+user[0]+" was already in the lab<br/>"
        end
      end
        
      redirect_to(:back, :notice=>notice)
    else
      redirect_to(:back, :alert=>"No import file specified.")
    end
  end
  
  def progress
    
    @lab_user=LabUser.find_by_id(params[:id])
    unless @lab_user.user.id==current_user.id || @admin then 
      @lab_user=LabUser.new#dummy
    end
    render :partial => 'shared/lab_progress' 
  end
  
  def user_token
     if params[:dir]=="asc" then
      dir = "ASC"
      @dir = "desc"
    else 
      dir = "DESC"
      @dir = "asc"
    end
    order = params[:sort_by]!=nil ? "#{params[:sort_by]} #{dir}" : "" 
    @users= User.order(order).paginate(:page=>params[:page], :per_page=>10)
  end
  
  private #-----------------------------------------------
  # return a array of users based on the input (list of checked checkboxes)
  def get_users_from(u_list)
    u_list=[] if u_list.blank?
    return u_list.collect{|u| User.find_by_id(u.to_i)}.compact
  end
end
