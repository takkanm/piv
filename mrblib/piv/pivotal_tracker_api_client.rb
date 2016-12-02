module Piv
  class PivotalTrackerApiClient
    API_HOST  = 'www.pivotaltracker.com'
    PATH_BASE = '/services/v5'

    def initialize(project_id, token)
      @token = token
      @project_id = project_id
    end

    def me
      get('/me')
    end

    def memberships
      get("/projects/#{@project_id}/memberships")
    end

    def stories(query = {})
      path = "/projects/#{@project_id}/stories"
      path = [path, query.map {|k,v| "#{k}=#{v}" }.join('&')].join('?')

      get(path)
    end

    def story(story_id)
      get("/projects/#{@project_id}/stories/#{story_id}")
    end

    def finish(story_id)
      # NOTE: SimpleHttp is support HTTP1.0
      put(
        "/projects/#{@project_id}/stories/#{story_id}",
        {'current_state' => 'finished'},
        {'Content-Type'  => 'application/json'}
      )
    end

    def current_iteration
      get("/projects/#{@project_id}/iterations?scope=current")
    end

    def get(path, header = {})
      client.request('GET', [PATH_BASE, path].join('/'), header.merge(default_header)).body
    end

    def put(path, body, header = {})
      body_content = body.to_json
      header["Content-Length"] = body_content.length
      header["Body"] = body_content
      client.request('PUT', [PATH_BASE, path].join(''), header.merge(default_header)).body
    end

    def default_header
      {'X-TrackerToken' => @token}
    end

    def client
      @client ||= SimpleHttp.new('https', API_HOST)
    end
  end
end
