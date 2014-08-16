class Feature < Sequel::Model

  # We don't want more than one task to be associated with a gene or set of
  # overlapping genes at any point of time.
  #many_to_one  :task

  plugin        :class_table_inheritance,
    key:         :klass,
    table_map:   {:'Feature::UserCreated' => :features_user_created}

  many_to_one   :ref_seq

  def ==(other)
    v1 = self.values
    v2 = other.values
    [v1, v2].each{|v| v.delete :id}
    v1 == v2
  end

  # When removing this gene from database, ensure overlapping genes and task
  # associated with them is removed as well.
  #def destroy!
    #task.genes.each(&:destroy)
    #task.destroy
    #self
  #end

  class UserCreated < self

    many_to_one :for_task,
      key:   :for_task_id,
      class: :'Task::Curation'

    many_to_one :from_user,
      key:   :from_user_id,
      class: :User

    alias submitted_at created_at

    def task_type
      "CurationTask"
    end

    def description
      "Curated #{for_task.ref}:#{for_task.start}..#{for_task.end}."
    end
  end
end
