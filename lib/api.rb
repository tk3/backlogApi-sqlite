module Backlog
  module Api
    module Space
      def space
        get('/space')
      end
    end
  end
end

module Backlog
  module Api
    module User
      def users
        get('/users')
      end
    end
  end
end

module Backlog
  module Api
    module Project
      def projects(params = {})
        get('/projects')
      end

      def versions(project_id_or_key)
        get('/projects/' + project_id_or_key.to_s + '/versions')
      end
    end

    module Category
      def categories(project_id_or_key)
        get('/projects/' + project_id_or_key.to_s + '/categories')
      end
    end

    module Status
      def statuses(project_id_or_key)
        get('/projects/' + project_id_or_key.to_s + '/statuses')
      end
    end

    module IssueType
      def issueTypes(project_id_or_key)
        get('/projects/' + project_id_or_key.to_s + '/issueTypes')
      end
    end
  end
end

module Backlog
  module Api
    module Priority
      def priorities(params = {})
        get('/priorities')
      end
    end
  end
end

module Backlog
  module Api
    module Issue
      def issues(params = {})
        get('/issues', params)
      end
    end
  end
end

