FactoryBot.define do
  factory :time_report do
    study_time { '0:30' }
    memo { '頑張りました!' }
    study_date { Time.current }
    association :user

    trait :setting do
      after(:create) { |t| create(:setting, user: t.user )}
    end

    trait :tags do
      after(:create) do |time_report|
        create_list(:tag, 3, time_reports: [time_report])
      end
    end

    trait :comments do
      after(:create) { |t| create_list(:comment, 3, time_report: t) }
    end

    trait :last_week do
      study_date { Time.current.prev_week }
    end
  end
end
