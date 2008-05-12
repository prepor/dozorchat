role :app, "82.146.46.183"

role :db, "82.146.46.183", {:primary=>true}

role :www, "82.146.46.183"

set :application, "dozorchat"

set :deploy_to, "/home/dozorchat/www"

set :deploy_via, :checkout

set :mongrel_config, "/home/dozorchat/mongrel_cluster.yml"

set :password, "zmnlpde"

set :rails_env, "production"

set :repository, "http://svn2.assembla.com/svn/dozorchat"

set :runner, "root"

set :scm, "subversion"

set :scm_password, "hzdsed"

set :scm_username, "preprocessor"

set :use_sudo, false

set :user, "root"
# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
# set :deploy_to, "/var/www/#{application}"

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
# set :scm, :subversion
