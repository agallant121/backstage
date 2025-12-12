class Child < ApplicationRecord
  belongs_to :user, inverse_of: :children

  validates :name, presence: true
  validates :age, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  def age_display
    return formatted_age_from_birthday if birthday.present?
    return "#{age} #{'year'.pluralize(age)}" if age.present?

    nil
  end

  private

  def formatted_age_from_birthday
    today = Date.current
    months = (today.year * 12 + today.month) - (birthday.year * 12 + birthday.month)
    months -= 1 if today.day < birthday.day

    return "#{months} #{'month'.pluralize(months)}" if months < 24

    years = months / 12
    "#{years} #{'year'.pluralize(years)}"
  end
end
