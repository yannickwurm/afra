require 'bcrypt'

class User < Sequel::Model

  one_to_many  :access_token,
    key:        :for_user_id

  one_to_many  :gene_models_contributed,
    key:        :from_user_id,
    class:      :'Gene::UserCreated'

  def tasks_attempted
    gene_models_contributed.map(&:for_task)
  end
end
