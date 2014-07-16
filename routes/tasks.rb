class Tasks < App::Routes
  before do
    content_type 'application/json'
  end

  get '/data/tasks/next' do
    user = AccessToken.user(request.session[:token])
    task = if (params[:type] == 'review')
      Task.give_for_review to: user
    else
      Task.give to: user
    end
    attrs = [:id, :ref, :start, :end, :tracks]
    task.to_json only: attrs
  end

  get '/data/task/:id/submissions' do |id|
    t = Task.with_pk(id)
    t.submissions.to_json
  end

  post '/data/tasks/:id' do
    submission = JSON.parse request.body.read
    user = AccessToken.user(request.session[:token])
    task = Task.with_pk params[:id]
    puts submission
    if submission.delete('only_save')
      task.save_for_later submission, from: user
    else
      task.register_submission submission, from: user
    end
    200
  end
end

