class UserMailer < ActionMailer::Base
  default from: "Notificação i-Diário <no@reply.com.br>"

  def notify_activation(user, entity)
    @user = user
    @entity = entity

    mail to: user.email, subject: "Conta de acesso ativada"
  end
end
