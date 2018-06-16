require 'rails_helper'

RSpec.describe 'users/index', type: :view  do
  before(:each) do
    assign(:users, [
        FactoryGirl.build_stubbed(:user, name: 'Поля', balance: 5000),
        FactoryGirl.build_stubbed(:user, name: 'Юля', balance: 3000)
    ])
    render
  end
  it 'renders player names' do
    expect(rendered).to match 'Поля'
    expect(rendered).to match 'Юля'
  end

  it 'renders player balances' do
    expect(rendered).to match '5 000 ₽'
    expect(rendered).to match '3 000 ₽'
  end

  it 'renders player name in right order' do
    expect(rendered).to match /Поля.*Юля/m
  end
end