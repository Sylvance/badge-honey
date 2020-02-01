module ApplicationHelper
    def is_current_path?(test_path)
        request.path == test_path
    end

    def current_class?(test_path)
        return ' border-b-2 border-green-500 hover:border-green-700' if is_current_path?(test_path)
        ''
    end
end
