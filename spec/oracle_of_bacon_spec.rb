require 'oracle_of_bacon'

require 'fakeweb'
require 'debugger'

describe OracleOfBacon do
  before(:all) { FakeWeb.allow_net_connect = false }
  describe 'instance', :pending => true do
    before(:each) { @orb = OracleOfBacon.new('fake_api_key') }
    describe 'when new' do
      subject { @orb }
      it { should_not be_valid }
    end
    describe 'when only From is specified' do
      subject { @orb.from = 'Carrie Fisher' ; @orb }
      it { should be_valid }
      it {subject.from.should eq('Carrie Fisher')}
      it {subject.to.should eq('Kevin Bacon')}
    end
    describe 'when only To is specified' do
      subject { @orb.to = 'Ian McKellen' ; @orb }
      it { should be_valid }
      it {subject.from.should eq('Kevin Bacon')}
      it {subject.to.should eq('Ian McKellen')}
    end
    describe 'when From and To are both specified' do
      context 'and distinct' do
        subject { @orb.to = 'Ian McKellen' ; @orb.from = 'Carrie Fisher' ; @orb }
        it { should be_valid }
        it {subject.from.should eq('Carrie Fisher')}
        it {subject.to.should eq('Ian McKellen')}
      end
      context 'and the same' do
        subject {  @orb.to = @orb.from = 'Ian McKellen' ; @orb }
        it { should_not be_valid }
      end
    end
  end
  describe 'parsing XML response', :pending => true do
    describe 'for unauthorized access/invalid API key' do
      subject { OracleOfBacon::Response.new(File.read 'spec/unauthorized_access.xml') }
      it {subject.type.should eq(:error)}
      it {subject.data.should eq('Unauthorized access')}
    end
    describe 'for a normal match', :pending => false do
      subject { OracleOfBacon::Response.new(File.read 'spec/graph_example.xml') }
      it {subject.type.should eq(:graph)}
      it {subject.data.should eq(['Carrie Fisher', 'Under the Rainbow (1981)',
                              'Chevy Chase', 'Doogal (2006)', 'Ian McKellen'])}
    end
    describe 'for a normal match (backup)', :pending => false do
      subject { OracleOfBacon::Response.new(File.read 'spec/graph_example2.xml') }
      it {subject.type.should eq(:graph)}
      it {subject.data.should eq(["Ian McKellen", "Doogal (2006)", "Kevin Smith (I)",
                              "Fanboys (2009)", "Carrie Fisher"])}
    end
    describe 'for a spellcheck match', :pending => false do
      subject { OracleOfBacon::Response.new(File.read 'spec/spellcheck_example.xml') }
      it{subject.type.should eq(:spellcheck)}
      it{subject.data.should have(34).elements}
      it{subject.data.should include('Anthony Perkins (I)')}
      it{subject.data.should include('Anthony Parkin')}
    end
    describe 'for unknown response', :pending => false do
      subject { OracleOfBacon::Response.new(File.read 'spec/unknown.xml') }
      it{subject.type.should eq(:unknown)}
      it{subject.data.should match(/unknown/i)}
    end
  end
  describe 'constructing URI', :pending => true do
    subject do
      oob = OracleOfBacon.new('fake_key')
      oob.from = '3%2 "a' ; oob.to = 'George Clooney'
      oob.make_uri_from_arguments
      oob.uri
    end
    it { should match(URI::regexp) }
    it { should match /p=fake_key/ }
    it { should match /b=George\+Clooney/ }
    it { should match /a=3%252\+%22a/ }
  end
  describe 'service connection', :pending => true do
    before(:each) do
      @oob = OracleOfBacon.new
      @oob.stub(:valid?).and_return(true)
    end
    it 'should create XML if valid response' do
      body = File.read 'spec/graph_example.xml'
      FakeWeb.register_uri(:get, %r(http://oracleofbacon\.org), :body => body)
      OracleOfBacon::Response.should_receive(:new).with(body)
      @oob.find_connections
    end
    it 'should raise OracleOfBacon::NetworkError if network problem' do
      FakeWeb.register_uri(:get, %r(http://oracleofbacon\.org),
        :exception => Timeout::Error)
      lambda { @oob.find_connections }.
        should raise_error(OracleOfBacon::NetworkError)
    end
  end

end
      
