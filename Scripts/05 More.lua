-- �w�i�擾�[�u ������������������������������������������������������������������������������������
function GetSongExBackground( songdir )
	local bgName = {"background", "bg"};
	local extension = {".jpg", ".png", ".bmp", ".gif"};
	for i=1, #bgName do
		for j=1, #extension do
			if File.Read(songdir..bgName[i]..extension[j])~=nil then
				return (songdir..bgName[i]..extension[j])
			end
		end
	end
	return nil
end

-- �o�i�[�擾�[�u ����������������������������������������������������������������������������������
function GetSongExBanner( songdir )
	local bannerName = {"banner", "bn"};
	local extension = {".jpg", ".png", ".bmp", ".gif"};
	for i=1, #bannerName do
		for j=1, #extension do
			if File.Read(songdir..bannerName[i]..extension[j])~=nil then
				return (songdir..bannerName[i]..extension[j])
			end
		end
	end
	return nil
end

-- 2P�Ȃ�w���W�𔽓]������ ������������������������������������������������������������������������
-- SCREEN_CENTER_X+[X���W]*Screen2PMirror()
function Screen2PMirror()
	if GAMESTATE:IsHumanPlayer( PLAYER_1 ) then
		return 1
	end
	return -1
end

-- �I�����C���Ȃ�P��Ԃ� ��������������������������������������������������������������������������
function SMOnlineToNum()
	if IsNetSMOnline() then
		return 1
	end
	return 0
end

-- ���C�t�o�[�̈ʒu ��������������������������������������������������������������������������������
function LifeBarPosition( pn )
	return string.find(GAMESTATE:GetPlayerState(pn):GetPlayerOptionsString("ModsLevel_Preferred"), "Reverse") and SCREEN_BOTTOM or SCREEN_TOP;
end

-- ���o�[�X�Ȃ�-1��Ԃ� ����������������������������������������������������������������������������
function OffReverseToNum( pn )
	return string.find(GAMESTATE:GetPlayerState(pn):GetPlayerOptionsString("ModsLevel_Preferred"), "Reverse") and -1 or 1;
end;

-- �v���C���O�̋ȃC���t�H�̕\�� ��������������������������������������������������������������������
function NextScreenNetSelectMusic()
	if ThemePrefs.Get("SkipScreenStageInformation") then
		return Branch.GameplayScreen()
	end
	return "ScreenStageInformation"
end

-- 10�i��32�i�ϊ� ����������������������������������������������������������������������������������
-- ���g�p
function IntToInt32bit( n )
	n = tonumber( n )
	if n == nil then
		return nil
	end
	n = math.floor( n )
	local s = ""
	local array = {}
	local numstr = {
		"0","1","2","3","4","5","6","7","8","9",	--  0- 9
		"a","b","c","d","e","f","g","h","i","j",	-- 10-19
		"k","l","m","n","o","p","q","r","s","t",	-- 20-29
		"u","v",									-- 30-31
	}
	while n >= 32 do
		array[#array+1] = n % 32
		n = (n - array[#array]) / 32
	end
	array[#array+1] = n
	for i=1, #array do
		s = numstr[array[i]+1] .. s					-- Lua�̔z���1����n�܂�
	end
	return s
end

-- �l������ ����������������������������������������������������������������������������������������
function GetFitXModFromMMod( MMod, pn, iEntry )
	if MMod <= 0 then
		return 0
	end
	local pState = GAMESTATE:GetPlayerState(pn)
	local song, steps
	if GAMESTATE:IsCourseMode() then
		local SongOrCourse, StepsOrTrail
		SongOrCourse = GAMESTATE:GetCurrentCourse()
		StepsOrTrail = GAMESTATE:GetCurrentTrail(pn)
		entry = StepsOrTrail:GetTrailEntries();
		song = entry[iEntry]:GetSong();
		steps = entry[iEntry]:GetSteps();
	else
		song = GAMESTATE:GetCurrentSong()
		steps = GAMESTATE:GetCurrentSteps(pn)
	end
	local XMod = 0
	if song and steps then
		local mtype = File.Read( "DefaultMoreSave/MModType.txt" )
		if not mtype then
			mtype = "Max"
		end
		local fitBPM
		local tempBPM = 0
		local invalidSecond = 5			-- Max and Min
		local totalSecond = 0			-- Medium
		local totalSecBPM = 0			-- Medium
		local maxContinuedSecond = 0	-- Main
		local timingData = steps:GetTimingData()
		local bpms = timingData:GetBPMsAndTimes()
		local data = {}
		for i=1, #bpms do
			data[i] = split("=", bpms[i])
			data[i][1], data[i][2] = tonumber(data[i][1]), tonumber(data[i][2])
		end
		for i=1,#data do
			local nowElapsedTime = timingData:GetElapsedTimeFromBeat(data[i][1])
			local nextElapsedTime
			if i==#data then
				nextElapsedTime = song:GetLastSecond()
			else
				nextElapsedTime = timingData:GetElapsedTimeFromBeat(data[i+1][1])
			end
			local continuedTime = nextElapsedTime - nowElapsedTime
			if mtype == "Max" or mtype == "Min" then
				if not fitBPM then
					fitBPM = data[i][2]
				end
				if continuedTime > invalidSecond then
					if mtype == "Max" then
						fitBPM = math.max(fitBPM, data[i][2])
					else
						fitBPM = math.min(fitBPM, data[i][2])
					end;
				end
			elseif mtype == "Medium" then
				totalSecond = totalSecond + continuedTime
				totalSecBPM = totalSecBPM + continuedTime * data[i][2]
				if i==#data then
					fitBPM = totalSecBPM / totalSecond
				end
			else
				if continuedTime > maxContinuedSecond then
					maxContinuedSecond = continuedTime
					fitBPM = data[i][2]
				elseif continuedTime == maxContinuedSecond then
					fitBPM = math.max(fitBPM, data[i][2])
				end
			end
			tempBPM = math.max(tempBPM, data[i][2])
		end
		if not fitBPM then
			fitBPM = tempBPM
		end
		XMod = MMod / fitBPM
		if XMod == 0 then
			XMod = pState:GetCurrentPlayerOptions():GetXMod()
		end
	end
	return XMod
end
-- ���[�_�l�𗅗� ����������������������������������������������������������������������������������
function RaderValueString( pn )
	if GAMESTATE:GetCurrentSong() then
		local rv = GAMESTATE:GetCurrentSteps( pn ):GetRadarValues( pn )
		local text = string.format("%i/%i/%i/%i/%i/%i",
			rv:GetValue("RadarCategory_TapsAndHolds"),
			rv:GetValue("RadarCategory_Jumps"),
			rv:GetValue("RadarCategory_Hands"),
			rv:GetValue("RadarCategory_Holds"),
			rv:GetValue("RadarCategory_Mines"),
			rv:GetValue("RadarCategory_Rolls")
		)
		return text
	end
	return ""
end
