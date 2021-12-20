# frozen_string_literal: true

shared_examples_for 'a flex' do
  it 'is not a user' do
    expect(flex).not_to be_user
  end

  it 'is not a producer' do
    expect(flex).not_to be_producer
  end

  it 'is a flexible technology' do
    expect(flex).to be_flex
  end
end

shared_examples_for 'a producer' do
  it 'is not a user' do
    expect(producer).not_to be_user
  end

  it 'is a producer' do
    expect(producer).to be_producer
  end

  it 'is not a flexible technology' do
    expect(producer).not_to be_flex
  end
end

shared_examples_for 'a user' do
  it 'is a user' do
    expect(user).to be_user
  end

  it 'is not a producer' do
    expect(user).not_to be_producer
  end

  it 'is not a flexible technology' do
    expect(user).not_to be_flex
  end
end
