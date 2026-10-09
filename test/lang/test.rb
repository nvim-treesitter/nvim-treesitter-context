# {{TEST}}
# frozen_string_literal: true

# BUG: The contexts need newlines or they don't appear

# Comment before module starts
module Bar # {{CONTEXT}}
  # Comment after module starts


  # {{CURSOR}}
  # Comment before class starts
  class Foo # {{CONTEXT}}
    # Comment after class starts


    # {{CURSOR}}
    # Comment before singleton class starts
    class << self # {{CONTEXT}}
      # Comment after singleton class starts


      # {{CURSOR}}
      # Comment before method starts
      def run # {{CONTEXT}}
        # Comment after method starts


        # {{CURSOR}}
        if false # {{CONTEXT}}
          # Comment after if starts


          # {{CURSOR}}
          (20..30).each do |element| # {{CONTEXT}}
            # Comment after block starts


            block.call(element) # {{CURSOR}}
          end # {{POPCONTEXT}}
        else # {{CONTEXT}}
          # Comment after else starts


          1 + 1 #{{CURSOR}}
        end # {{POPCONTEXT}}
      end # {{POPCONTEXT}}
    end # {{POPCONTEXT}}
    # {{POPCONTEXT}} # XXX: Extra pop to pop the else context

    # Comment before singleton method
    def self.other_method # {{CONTEXT}}
      # Comment after singleton method starts


      # {{CURSOR}}
      unless false # {{CONTEXT}}
        # Comment after unless starts


        # {{CURSOR}}
        (10..20).each do |element| # {{CONTEXT}}
          # Comment after block starts


          block.call(element) # {{CURSOR}}
        end # {{POPCONTEXT}}
      else # {{CONTEXT}}
        # Comment after else starts


        1 + 1 # {{CURSOR}}
      end # {{POPCONTEXT}}
    end # {{POPCONTEXT}}
    # {{POPCONTEXT}} # XXX: Extra pop to pop the else context

    # Comment before method starts
    def run(&block) # {{CONTEXT}}
      # Comment after method starts


      # {{CURSOR}}
      unless false # {{CONTEXT}}
        # Comment after unless starts


        # {{CURSOR}}
        (1..10).each do |element| # {{CONTEXT}}
          # Comment after block starts


          block.call(element) # {{CURSOR}}
        end # {{POPCONTEXT}}
      else # {{CONTEXT}}
        # Comment after else starts


        1 + 1 # {{CURSOR}}
      end
    end
  end
end

# {{TEST}}

RSpec.describe 'foo' do # {{CONTEXT}}
  context 'bar' do # {{CONTEXT}}
    shared_context 'shared context' do # {{CONTEXT}}
      it 'test' do # {{CONTEXT}}




        expect(1).to eq(1) # {{CURSOR}}
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
