module IeducarApi
  class Students < Base
    def fetch(params = {})
      params.merge!(path: "module/Api/Aluno", resource: "todos-alunos")

      super
    end
  end
end