module IeducarApi
  class StudentEnrollments < Base
    def fetch(params = {})
      params.reverse_merge!(
        path: 'module/Api/Matricula',
        resource: 'matriculas-escola'
      )

      raise ApiError, 'É necessário informar o ano' if params[:ano].blank?

      super
    end
  end
end
