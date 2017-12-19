class ESP32_LM75A

	READ_TEMP   = 0.chr
	CONFIG      = 1.chr
	THYST       = 2.chr
	TOS         = 3.chr
	READ_PRODID = 7.chr

	def initialize(address,port=1)
		@port    = port
		@address = address
		@config  = nil
	end

	def init
		@i2c = ESP32::I2C.new(@port)
		@i2c.init
	end

	def celsius
    raw = @i2c.send_receive(READ_TEMP,@address,ESP32::I2C::SHORT)  
    return raw / 256.0
	end

	def get_thyst
    raw = @i2c.send_receive(THYST,@address,ESP32::I2C::SHORT) 
    return raw / 256.0
	end

	def set_thyst(cent)
		thys  = (cent * 256.0).to_i
		upper = (thys / 256  ).to_i
		lower = (thys % 256  )
		puts "sending #{upper} #{lower}"
		send_data = upper.chr + lower.chr
    raw = @i2c.send_send(@address,THYST,send_data) 
	end

	def set_tos(cent)
		thys  = (cent * 256.0).to_i
		upper = (thys / 256  ).to_i
		lower = (thys % 256  )
		puts "sending TOS #{upper} #{lower}"
		send_data = upper.chr + lower.chr
    raw = @i2c.send_send(@address,TOS,send_data) 
	end

	def get_tos
    raw = @i2c.send_receive(TOS,@address,ESP32::I2C::SHORT)  
    return raw / 256.0
	end

	def fahrenheit
		return celsius * 1.8 + 32.0
	end

	def thyst_fahrenheit
		return get_thyst * 1.8 + 32.0
	end

	def tos_fahrenheit
		return get_tos * 1.8 + 32.0
	end

	def get_configuration
    @config = @i2c.send_receive(CONFIG,@address,ESP32::I2C::UNSIGNED_CHAR)
    puts " config = #{@config}"
    @config
	end

	def get_prodid
    @prodid = @i2c.send_read_immediate(READ_PRODID,@address,ESP32::I2C::UNSIGNED_CHAR) 
    @prodid
	end

	def fault_queue
		if @config.nil?
			get_configuration
		end
		fq = @config & 0b00011000
		case fq
			when 0
				fq = 1
			when 8
				fq = 2
			when 16
				fq = 4
			when 24
				fq = 6
			else
				fq = -1
		end
		fq
	end

  def os_active
		if @config.nil?
			get_configuration
		end
		osa = @config & 0b00000100
		if 0 == osa
			osa = :low
		else
			osa = :high
		end
		osa
	end

  def mode
		if @config.nil?
			get_configuration
		end
		mod = @config & 0b00000010
		if 0 == mod
			mod = :comparator  # good for fan control
		else
			mod = :interrupt   # momentary signal only
		end
		mod
	end

  def shutdown
		if @config.nil?
			get_configuration
		end
		sd = @config & 0b00000001
		if 0 == sd
			sd = false
		else
			sd = true
		end
		sd
	end

	def set_config(config)
    @config = config
    @i2c.send_send(@address,CONFIG,config.chr)
	end
end

lm75a = ESP32_LM75A.new(73)
lm75a.init
puts
puts "fahrenheit  = #{lm75a.fahrenheit}"
puts
puts "configure thyst to 77"  
lm75a.set_thyst(130)
lm75a.set_tos(77)
puts
puts "thyst c     = #{lm75a.get_thyst}"
puts
puts "tos c       = #{lm75a.get_tos}"
puts "tos f       = #{lm75a.tos_fahrenheit}"
puts
lm75a.set_config(26)
puts "configuration = #{lm75a.get_configuration}"
puts
#puts "fault queue = #{lm75a.fault_queue}"
puts
puts "prodid       = #{lm75a.get_prodid}"
puts
