require 'yaml'
require 'date'

class Task < Sequel::Model

  one_to_many   :genes

  plugin        :class_table_inheritance,
    key:         :type,
    table_map:   {:'Task::Curation' => :tasks_curation, :'Task::Review' => :tasks_review}

  def tracks
    genes.first.tracks
  end

  class << self
    def distribution_dataset
      db[:task_distribution]
    end

    def give(to: nil)
      raise "Task can only be given 'to' a User" unless to.is_a? User

      # First check if a task was already assigned to the user.
      if t = distribution_dataset.where(user_id: to.id).first
        return Task.with_pk(t[:task_id])
      end

      # Assign user a new task.
      available_tasks = where(id: to.tasks_attempted.map(&:id)).invert.where(state: 'ready').where(difficulty: 1)
      available_tasks_with_highest_priority = available_tasks.where(priority: available_tasks.max(:priority))
      task = available_tasks_with_highest_priority.offset(Sequel.function(:floor, Sequel.function(:random) * available_tasks_with_highest_priority.count)).first
      task.set_running_state and task.add_to_distributed_list(to)
    end

    def give_for_review(to: nil)
      raise "Task can only be given 'to' a User" unless to.is_a? User
      available_tasks = Review.offset(Sequel.function(:floor, Sequel.function(:random) * Review.count)).first
      available_tasks
    end
  end

  def register_submission(submission, from: nil)
    yield
    #register_user_contribution from
    #if contributions.count == 3 # and type == 'curation'
      #set_
    #else
      increment_priority and set_ready_state and remove_from_distributed_list(from)
    #end
  end

  def auto_check
    submissions.each_cons(2) do |s1, s2|
      return false unless s1 == s2
    end
    true
  end

  def set_ready_state
    self.state = 'ready'
    self.save
    self
  end

  def set_running_state
    self.state = 'running'
    self.save
    self
  end

  def distribution_dataset
    self.class.distribution_dataset
  end

  def add_to_distributed_list(user)
    distribution_dataset.insert(task_id: self.id, user_id: user.id)
    self
  end

  def remove_from_distributed_list(user)
    distribution_dataset.where(task_id: self.id, user_id: user.id).delete
    self
  end

  def increment_priority
    self.priority += 1
    self.save
    self
  end

  class Curation < self

    one_to_many :submissions,
      class:     :'Gene::UserCreated',
      key:       :for_task_id

    def save_for_later(submission, from: nil)
      raise "Submission should come 'from' a User" unless from.is_a? User
      submission.map do |id, feature|
        f = feature_detail_hash feature
        f[:from_user_id] = from.id
        f[:for_task_id]  = self.id
        Gene::UserCreated.create f
      end
    end

    def register_submission(submission, from: nil)
      raise "Submission should come 'from' a User" unless from.is_a? User

      ### HACK - remove this when annotation saving is robust
      File.write(".submissions/#{from.id}_#{DateTime.now}.yml", YAML.dump(submission))
      ### HACK!!

      guc = nil
      super do
        guc = submission.map do |id, feature|
          f = feature_detail_hash feature
          f[:from_user_id] = from.id
          f[:for_task_id]  = self.id
          Gene::UserCreated.create f
        end
      end

      # Create review task.
      start, _end = (guc.map(&:start) + guc.map(&:end)).minmax
      r = Review.create(start: start, end: _end, ref: guc.first.ref)
      guc.each do |g|
        r.add_gene g
      end
    end

    def feature_detail_hash(feature)
      data = feature['data']
      {
        name:        data['name'],
        ref:         data['ref'],
        type:        data['type'],
        start:       data['start'],
        end:         data['end'],
        subfeatures: data['subfeatures'].map do |subfeature|
          subfeature = subfeature.values.first
          {start: subfeature['start'], end: subfeature['end'], type: subfeature['type']}
        end,
      }
    end
  end

  class Review < self
  end
end
