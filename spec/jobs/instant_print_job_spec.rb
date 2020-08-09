require 'rails_helper'

RSpec::Matchers.define_negated_matcher :not_include, :include
PARTICIPANT_PROPERTIES = ['one', 'two', 'three', 'four', 'five']

# Note: These suites don't test the invalid argument cases for the instant print job, since that is handled
# by the instant_print_requests_spec, and would just be duplicated here.
RSpec.describe InstantPrintJob, type: :job do
  let(:roster) { create(:roster, participant_properties: PARTICIPANT_PROPERTIES) }
  let(:hunt) { create(:hunt, roster: roster) }
  let(:current_round) { create(:round, hunt: hunt) }
  let(:template_pdf) { file_fixture('template_pdfs/allFields.pdf') }

  let(:ordering_params) { nil }
  let(:message) { nil }

  before(:each) do
    hunt.template_pdf.attach(io: template_pdf.open, filename: 'template_pdf.pdf', content_type: 'application/json')
  end

  after(:each) do
    hunt.template_pdf.purge
  end

  shared_examples 'runs with proper arguments' do
    def make_matcher(matcher)
      matcher
    end

    it 'invokes the pin press jar with proper arguments and saves the output' do
      expect(Kernel).to receive(:system).with(make_matcher(match(/^java -jar .* #{current_round.id} .* --fill 'http:\/\/.*\/%s'.*$/))) { true }
      InstantPrintJob.perform_later(hunt, ordering_params, message)
      expect(hunt.reload.template_pdf).to be_attached
    end
  end

  context 'with minimal arguments to instant print' do
    include_examples 'runs with proper arguments' do
      def make_matcher(matcher)
        matcher.and(not_include('--message', '--ordering'))
      end
    end
  end

  context 'with message argument and no orderings' do
    let(:message) { 'Testing the instant print' }
    include_examples 'runs with proper arguments' do
      def make_matcher(matcher)
        matcher.and(include("--message '#{message}'")).and(not_include('--ordering'))
      end
    end
  end

  [nil, 'testing Instant Print'].each do |current_message|
    context "with #{current_message.present? ? 'a message' : 'no message'} and " do
      let(:message) { current_message }

      def message_matcher(matcher)
        if message.present?
          matcher.and(include("--message '#{message}"))
        else
          matcher.and(not_include('--message'))
        end
      end

      describe '1 ordering' do
        let(:ordering_params) { [[PARTICIPANT_PROPERTIES[0], 'asc']] }
        include_examples 'runs with proper arguments' do
          def make_matcher(matcher)
            message_matcher(matcher.and(include("--ordering #{PARTICIPANT_PROPERTIES[0]}:asc")))
          end
        end
      end

      describe '3 orderings' do
        let(:ordering_params) { [[PARTICIPANT_PROPERTIES[0], 'asc'], [PARTICIPANT_PROPERTIES[1], 'desc'], [PARTICIPANT_PROPERTIES[2], 'desc']] }
        include_examples 'runs with proper arguments' do
          def make_matcher(matcher)
            # Order of orderings is important, so need to keep it all in the same string to be included.
            message_matcher(matcher.and(include("--ordering #{PARTICIPANT_PROPERTIES[0]}:asc --ordering #{PARTICIPANT_PROPERTIES[1]}:desc --ordering #{PARTICIPANT_PROPERTIES[2]}:desc")))
          end
        end
      end

      describe 'full orderings' do
        let(:ordering_params) { PARTICIPANT_PROPERTIES.map { |property| [property, %w[asc desc].sample] } }
        include_examples 'runs with proper arguments' do
          def make_matcher(matcher)
            message_matcher(matcher.and(include(ordering_params.map { |pair| "--ordering #{pair[0]}:#{pair[1]}" }.join(' '))))
          end
        end
      end
    end
  end
end
