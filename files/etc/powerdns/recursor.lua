function preresolve ( ip, domain, qtype )
	if qtype == pdns.TXT and string.lower(domain) == "the.time." then
		setvariable()
		return 0, {{qtype="16",ttl=1,place="1",content=os.date("\"%c\"")}}
	end
	if qtype == pdns.TXT and string.lower(domain) == "my.ip." then
		setvariable()
		return 0, {{qtype="16",ttl=1,place="1",content="\"" .. ip .. "\""}}
	end
end

function postresolve ( remoteip, domain, qtype, records, origrcode )
	if qtype == pdns.PTR then
		local firstptrset = false
		local ret = {}
		for key,val in ipairs(records) do
			if val.qtype == pdns.PTR then
				if firstptrset == false then
					table.insert(ret, val)
					firstptrset = true
				end
			else
				table.insert(ret, val)
			end
		end
		records = ret
	end
	return origrcode, records
end