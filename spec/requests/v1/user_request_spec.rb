require 'rails_helper'

RSpec.describe "V1::Users", type: :request do

  let!(:user) { create(:user, :setting) }
  let!(:experience) { create(:experience, user: user) }

  describe '#show' do
    it '正しいユーザー情報が取得できること' do
      get v1_user_path(user)
      json = JSON.parse(response.body)
      user = JSON.parse(json['user'])
      expect(response.status).to eq 200
      expect(user['id']).to eq user['id']
    end

    it 'タイムレポートとその経験値が取得できること' do
      time_report = create(:time_report, study_time: '0:20',
        user: user, memo: 'foo'
      )
      exp_record = create(
        :experience_record, experience_point: 20,
        user: user, time_report: time_report
      )

      get v1_user_path(user)
      json = JSON.parse(response.body)
      user = JSON.parse(json['user'])
      expect(response.status).to eq 200
      expect(user['time_reports'][0]['memo']).to eq 'foo'
      expect(user['time_reports'][0]['experience_record']['experience_point']).to eq 20
    end
  end

  describe '#create' do
    it 'ユーザーを作成できること' do
      user_params = attributes_for(:user)
      expect {
        post v1_users_path, params: { user: user_params }
      }.to change(User, :count).by(1)
      expect(response.status).to eq 201
    end
  end

  describe '#update' do
    it 'ユーザー情報を更新できること' do
      user_params = attributes_for(:user, email: 'foo@example.com')
      patch v1_user_path(user.id), params: { user: user_params }
      user.reload
      expect(user.email).to eq 'foo@example.com'
    end

    it 'ゲストアカウントは更新できないこと' do
      guest = create(:user, guest: true, email: 'guest2@example.com')
      user_params = attributes_for(:user, email: 'foo@example.com')
      patch v1_user_path(guest.id), params: { user: user_params }
      guest.reload
      expect(guest.email).to eq 'guest2@example.com'
    end
  end
end
