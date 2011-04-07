module RBAC
  module User
    def admin
      self.admin?
    end

    def developer
      self.developer?
    end

    def designer
      self.designer?
    end
  end
end

