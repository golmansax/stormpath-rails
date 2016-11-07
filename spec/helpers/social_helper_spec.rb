require 'spec_helper'

describe SocialHelper, type: :helper do
  describe '#box_class' do
    context 'social providers present' do
      before do
        allow(helper).to receive(:social_providers_present?).and_return(true)
      end

      it 'returnes col-sm-8' do
        expect(helper.box_class).to eq('small col-sm-8')
      end
    end

    context 'social providers absent' do
      before do
        allow(helper).to receive(:social_providers_present?).and_return(false)
      end

      it 'returnes col-sm-12' do
        expect(helper.box_class).to eq('large col-sm-12')
      end
    end
  end

  describe '#label_class' do
    context 'social providers present' do
      before do
        allow(helper).to receive(:social_providers_present?).and_return(true)
      end

      it 'returnes col-sm-12' do
        expect(helper.label_class).to eq('col-sm-12')
      end
    end

    context 'social providers absent' do
      before do
        allow(helper).to receive(:social_providers_present?).and_return(false)
      end

      it 'returnes col-sm-4' do
        expect(helper.label_class).to eq('col-sm-4')
      end
    end
  end

  describe '#input_class' do
    context 'social providers present' do
      before do
        allow(helper).to receive(:social_providers_present?).and_return(true)
      end

      it 'returnes col-sm-12' do
        expect(helper.input_class).to eq('col-sm-12')
      end
    end

    context 'social providers absent' do
      before do
        allow(helper).to receive(:social_providers_present?).and_return(false)
      end

      it 'returnes col-sm-8' do
        expect(helper.input_class).to eq('col-sm-8')
      end
    end
  end
end
