require 'json'

class Tasks < App::Routes

  before do
    content_type 'application/json'
  end

  get '/data/tasks/next' do
    user = AccessToken.user(request.session[:token])
    task = Task.give to: user

    #task.to_json only: [:id, :ref, :start, :end, :tracks]
    {
      id:      task.id,
      refSeqs: [
        {
          start:  0,
          end:    task.ref_seq.length,
          length: task.ref_seq.length,
          name:   task.ref_seq.seq_id,
          seqChunkSize: RefSeq::CHUNK_SIZE
        }
      ],
      ref:     task.ref_seq.seq_id,
      start:   task.start,
      end:     task.end,
      tracks:  task.tracks,
      trackList: "data/jbrowse/#{task.ref_seq.species}/#{task.ref_seq.asm_id}/trackList.json"
    }.to_json
  end

  post '/data/tasks/:id' do
    submission = JSON.parse request.body.read
    user = AccessToken.user(request.session[:token])
    task = Task.with_pk params[:id]
    task.register_submission submission, from: user
    200
  end
end
