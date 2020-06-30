class CreateTimeReports < ActiveRecord::Migration[6.0]
  def change
    create_table :time_reports do |t|
      t.references :user, null: false, foreign_key: true
      t.time

      t.timestamps
    end
  end
end
