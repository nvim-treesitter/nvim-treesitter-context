# frozen_string_literal: true

module Bar
  class Foo
    class << self
      def run # {{CONTEXT}}



        # {{CURSOR}}
        if false
          (20..30).each do |element|
            block.call(element)
          end
        else
          1 + 1
        end
      end
    end

    def self.other_method
      unless false
        (10..20).each do |element|
          block.call(element)
        end
      else
        1 + 1
      end
    end

    def run(&block)
      unless false
        (1..10).each do |element|
          block.call(element)
        end
      else
        1 + 1
      end
    end
  end
end

RSpec.describe 'foo' do
  context 'bar' do
    shared_context 'shared context' do
      it 'test' do
        expect(1).to eq(1)
      end
    end

    shared_examples 'shared examples' do
      it 'test' do
        expect(1).to eq(1)
      end
    end

    context 'xpto' do
      context 'other' do
        it 'test' do
          expect(1).to eq(1)
        end

        it_behaves_like 'shared examples' do
          let(:one) { 1 }
        end

        include_context 'shared examples' do
          let(:one) { 1 }
        end

        include_examples 'shared examples' do
          let(:one) { 1 }
        end
      end
    end
  end
end
