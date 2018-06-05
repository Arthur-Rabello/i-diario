FactoryGirl.define do
  factory :entity do
    name "Prefeitura"
    domain "127.0.0.1"
    config do
      { config: { database: "novo_educacao_test" } }
    end
  end
end
