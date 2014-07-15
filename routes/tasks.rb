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
    task.to_json only: [:id, :ref, :start, :end, :tracks]
  end

  post '/data/tasks/:id' do
    submission = JSON.parse request.body.read
    user = AccessToken.user(request.session[:token])
    task = Task.with_pk params[:id]
    task.register_submission submission, from: user
    200
  end
end

