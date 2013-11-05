require 'spec_helper'

describe Merit do

  describe '.area' do

    it 'defaults to :nl' do
      expect(Merit.area).to eq :nl
    end

  end

  describe '.within_area' do

    around(:each) do |example|
      Merit.within_area(:uk, &example)
    end

    it 'sets area to :uk' do
      expect(Merit.area).to eq :uk
    end

  end

end
