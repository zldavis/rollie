require "spec_helper"

module Rollie
  describe RateLimiter do

    before do
      @r = RateLimiter.new(SecureRandom.hex(8), count_blocked: true)
    end

    describe :within_limit do

      it "should require a block" do
        expect{ @r.within_limit }.to raise_error(ArgumentError)
      end

      it "should return status" do
        status = @r.within_limit do; end
        expect(status.count).to eq(1)
        expect(status.exceeded?).to be(false)
        expect(status.time_remaining).to eq(1000)
      end

      it "should execute block only while within limit" do
        count = 0
        status = nil
        30.times do
          status = @r.within_limit do
            count += 1
          end
        end
        expect(count).to eq(25)
        expect(status.count).to eq(30)
        expect(status.exceeded?).to be(true)
      end

      it "should block all actions within the window" do
        @r = RateLimiter.new(SecureRandom.hex(8), limit: 10, interval: 100, count_blocked: true)
        count = 0
        30.times do
          @r.within_limit do
            count += 1
          end
          sleep 0.004
        end
        expect(count).to eq(10)
      end

      it "should allow blocked actions not to be counted" do
        @r = RateLimiter.new(SecureRandom.hex(8), limit: 10, interval: 100, count_blocked: false)
        count = 0
        30.times do
          @r.within_limit do
            count += 1
          end
          sleep 0.0045
        end
        expect(count).to eq(20)
      end

    end

    describe :report_hit do
      before do
        @limiter = RateLimiter.new(SecureRandom.hex(8), count_blocked: false)
      end

      it "should return status" do
        status = @limiter.add_hit
        expect(status.count).to eq(1)
        expect(status.exceeded?).to be(false)
        expect(status.time_remaining).to eq(1000)
      end

      it "should increase count regardless of count_blocked setting" do
        35.times do
          @limiter.add_hit
          sleep 0.001
        end

        status = @limiter.add_hit
        expect(status.count).to eq(36)
        expect(status.exceeded?).to be(true)
      end
    end

    describe :count do

      it "should return the current count" do
        30.times do
          @r.within_limit do; sleep 0.001; end
        end

        expect(@r.count).to eq(30)

        @r = RateLimiter.new(SecureRandom.hex(8), limit: 10, count_blocked: false)

        30.times do
          @r.within_limit do; sleep 0.001; end
        end

        expect(@r.count).to eq(10)
      end

    end

  end
end
