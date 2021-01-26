describe Fastlane::Actions::MmToolkitAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The mm_toolkit plugin is working!")

      Fastlane::Actions::MmToolkitAction.run(nil)
    end
  end
end
