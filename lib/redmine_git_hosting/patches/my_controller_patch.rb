module RedmineGitHosting
  module Patches
    module MyControllerPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          alias_method_chain :account, :git_hosting

          helper :gitolite_public_keys
        end
      end


      module InstanceMethods

        def account_with_git_hosting(&block)
          # Previous routine
          account_without_git_hosting(&block)

          # Set public key values for view
          set_public_key_values
        end


        private


        # Add in values for viewing public keys:
        def set_public_key_values
          @gitolite_user_keys   = @user.gitolite_public_keys.user_key.active.order('title ASC, created_at ASC')
          @gitolite_deploy_keys = @user.gitolite_public_keys.deploy_key.active.order('title ASC, created_at ASC')
          @gitolite_public_keys = @gitolite_user_keys + @gitolite_deploy_keys
          @gitolite_public_key  = @gitolite_public_keys.detect{|x| x.id == params[:public_key_id].to_i}

          if @gitolite_public_key.nil?
            if params[:public_key_id]
              # public_key specified that doesn't belong to @user.  Kill off public_key_id and try again
              redirect_to :public_key_id => nil, :tab => nil
              return
            else
              @gitolite_public_key = GitolitePublicKey.new
            end
          end
        end

      end


    end
  end
end

unless MyController.included_modules.include?(RedmineGitHosting::Patches::MyControllerPatch)
  MyController.send(:include, RedmineGitHosting::Patches::MyControllerPatch)
end
