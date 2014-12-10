require_relative "../libraries/ip_finder"

describe Chef::IPFinder do

  let(:base_node) do
    {
      'network' => {
        'interfaces' => {
          'eth0' => {
            'addresses' => {
              '10.20.112.32' => {}
            }
          },
          'eth1' => {
            'addresses' => {
              '200.23.142.11' => {},
              '2600:3c00::f03c:91ff:fedf:f63c' => {}
            }
          },
          'eth2' => {
            'addresses' => {
              '239.12.11.123' => {}
            }
          },
          'lo' => {
            'addresses' => {
              '127.0.0.1' => {}
            }
          }
        }
      }
    }
  end

  describe '.find_one' do
    context "cloud" do
      let(:cloud_node) do
        base_node.merge(
          'cloud' => {
            'public_ipv4' => '66.23.113.32',
            'local_ipv4' => '10.2.123.14'
          }
        )
      end

      it 'returns private ipv4 from node attributes' do
        described_class.find_one(cloud_node, :private_ipv4).should == '10.2.123.14'
      end

      it 'returns public ipv4 from node attributes' do
        described_class.find_one(cloud_node, :public_ipv4).should == '66.23.113.32'
      end
    end

    it 'returns nil when cant find an ip' do
      described_class.find_one(base_node, :private_ipv6).should be_nil
    end

    it 'finds a local ipv4 address' do
      described_class.find_one(base_node, %w(local ipv4)).should == '10.20.112.32'
    end
  end

  describe '.find' do
    context "cloud" do
      let(:cloud_node) do
        base_node.merge(
          'cloud' => {
            'public_ipv4' => '66.23.113.32',
            'local_ipv4' => '10.2.123.14'
          }
        )
      end

      it 'returns private ipv4 from node attributes' do
        described_class.find(cloud_node, :private_ipv4).should == ['10.2.123.14', '10.20.112.32']
      end

      it 'returns public ipv4 from node attributes' do
        described_class.find(cloud_node, :public_ipv4).should == ['66.23.113.32', '200.23.142.11']
      end
    end

    it 'finds a private ipv4 address' do
      described_class.find(base_node, %w(private ipv4)).should == ['10.20.112.32']
    end

    it 'finds a local ipv4 address' do
      described_class.find(base_node, %w(local ipv4)).should == ['10.20.112.32']
    end

    it 'returns private address from attributes when available' do
      node = base_node.merge('privateaddress' => '192.168.12.132')
      described_class.find(node, :private_ipv4).should == ['192.168.12.132', '10.20.112.32']
    end

    it 'finds a public ipv4 address' do
      described_class.find(base_node, :public_ipv4).should == ['200.23.142.11']
    end

    it 'finds a unicast public ipv4 address' do
      described_class.find(base_node, :unicast_public_ipv4).should == ['200.23.142.11']
    end

    it 'finds a global ipv4 address' do
      described_class.find(base_node, :global_ipv4).should == ['200.23.142.11']
    end

    it 'finds a loopback address' do
      described_class.find(base_node, :loopback).should == ['127.0.0.1']
    end

    it 'finds a global ipv6 address' do
      described_class.find(base_node, ['global', 'ipv6']).should == ['2600:3c00::f03c:91ff:fedf:f63c']
    end

    it 'finds a multicast address' do
      described_class.find(base_node, :multicast).should == ['239.12.11.123']
    end

    it 'returns nil when cant find an address' do
      described_class.find(base_node, %w(loopback ipv6)).should be_empty
    end
  end

  describe '.find_by_interface' do
    it 'finds the ipv4 for the given interface' do
      described_class.find_by_interface(base_node, 'eth1').should == '200.23.142.11'
    end

    it 'finds the global ipv6 for the given interface' do
      described_class.find_by_interface(base_node, 'eth1', :global_ipv6).should == '2600:3c00::f03c:91ff:fedf:f63c'
    end

    it 'returns nil when cant find an interface' do
      described_class.find_by_interface(base_node, 'ne0').should be_nil
    end
  end

  describe ".ip_to_scope" do
    it 'returns the scope of a given ip address' do
      described_class.ip_to_scope("127.0.0.1").should == ["node"]
      described_class.ip_to_scope("192.168.1.12").should == ["private"]
      described_class.ip_to_scope("200.32.190.11").should == ["public"]
      described_class.ip_to_scope("0.0.0.0").sort.should == ["node", "private", "public"]
    end
  end

  describe ".find_all" do
    it 'finds all the ipv4 addresses in the node' do
      described_class.find_all(base_node).should == { "node" => ["127.0.0.1"], "private" => ["10.20.112.32"], "public" => ["200.23.142.11"] }
    end

    it 'finds all the ipv6 addresses in the node' do
      described_class.find_all(base_node, 'ipv6').should == { "public" => ["2600:3c00::f03c:91ff:fedf:f63c"] }
    end
  end
end