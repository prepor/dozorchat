class Mailer < ActionMailer::Base
  def restore_pass(email, pass)
    recipients email
    subject    "Восстановление пароля"
    body       :pass => pass
    from       "robot@dozorchat.ru"
    content_type "text/html"
  end

end
