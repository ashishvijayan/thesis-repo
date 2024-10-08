 sca;
%clear all;
close all;
clc;

loc=[];
all_target_locations = [];
target_array = [];

% ----------------------------------------------------------------------
%%
uiwait(msgbox('Select the working directory!','modal'));
fold = uigetdir;


% ----------------------Extract all sheets-------------------------------

[fileinfo,pathTraining,idx] = ...
    uigetfile({'*.xls';'*.*'},'Training File Selector');

[filetarget,pathTarget,idx2] = ...
    uigetfile({'*.xls';'*.*'},'Target File Selector');

catchTrials = 0;

%------------------------Participant Info----------------------------------
%%

participant = Exp_subject_info;
subjectName = participant.Name;
subjectHand = participant.Hand;

subjectNum = participant.Number;
subjectCond = participant.Cond;

Subfold = fullfile(fold,subjectName);
status = mkdir(Subfold);
if status ~= 1
    mkdir(Subfold);
    cd(Subfold);
else
    cd(Subfold);
end

if ~strcmp(subjectCond,'NA') && ~strcmp(subjectCond,'na')
    Subfold2 = fullfile(Subfold,subjectCond);
    status = mkdir(Subfold2);
    if status ~= 1
        mkdir(Subfold2);
        cd(Subfold2);
    else
        cd(Subfold2);
    end
end


pixeltocmratioX = 19.3;
pixeltocmratioY = 19.3;
pixeltocmratio = 19.3;
ScrCorrectfactorx = -180.620;
ScrCorrectfactory = -310.620;

%%
%-------------------------------------starting PTB---------------------------

Screen('Preference', 'SkipSyncTests', 1)
[wPtr,rect] = Screen('OpenWindow',0,[0,0,0]);       %dimension in pixels = [0,0,1366,768]
[m,n] = Screen('WindowSize',wPtr);
[xCenter,yCenter] = RectCenter(rect);

vbl = Screen('Flip', wPtr);
ifi = Screen('GetFlipInterval', wPtr);
waitframes = 1;

CursorColor = [255,255,0];
StartColor = [0,255,0];
TargetColor = [255,0,0];

%----------------------------Training Data from sheet------------------------------
%%


table_exp = readtable(fullfile(pathTraining,fileinfo));
table_targets = readtable(fullfile(pathTarget,filetarget));

numberTrials = height(table_exp);
%         numberTrials = 2;

CursorWidth = table_exp{1,2}*pixeltocmratioX;       %in pixels now
CursorHeight = table_exp{1,3}*pixeltocmratioY;

for N=1:numberTrials
    PointSx = rect(3)-table_targets{table_exp{N,4},1};
    PointSy = table_targets{table_exp{N,4},2};
    PointSW = table_targets{table_exp{N,4},3}*pixeltocmratioX;
    PointSH = table_targets{table_exp{N,4},4}*pixeltocmratioY;
    StartRect(N,:) = [PointSx - PointSW/2 , PointSy - PointSH/2 , ...
        PointSx + PointSW/2 , PointSy + PointSH/2];
end

for N=1:numberTrials
    PointTx = rect(3)-table_targets{table_exp{N,5},6};
    PointTy = table_targets{table_exp{N,5},7};
    PointTW = table_targets{table_exp{N,5},8}*pixeltocmratioX;
    PointTH = table_targets{table_exp{N,5},9}*pixeltocmratioY;
    TargetRect(N,:) = [PointTx-PointTW/2 , PointTy-PointTH/2 ,...
        PointTx+PointTW/2 , PointTy+PointTH/2];
end



%%
%-------------------------------------Trial---------------------------

Totalpoint = 0;

for N=1:numberTrials
    
    Data = [];
    dataPlot=[];
    
    IsRot = 0;
    IsTargetJump = 0;
    IsCursorJump = 0;
    IsTranslation = 0;
    IsGain = 0;
    startCursorDist = 0;
    
    [Sx,Sy] = RectCenter(StartRect(N,:));
    [Tx,Ty] = RectCenter(TargetRect(N,:));
    
    startTime = table_exp{1,6};         %in sec
    Trial_time = table_exp{1,7};
    RecordingTime = table_exp{1,8};
    NextTarget = table_exp{N,9};        %switch + new target number
    TargetJumpTime = table_exp{N,11};
    beep_number = table_exp{N,12};
    CursorRotation = table_exp{N,13};           %in degrees
    Translation = table_exp{N,17};      %switch
    Xtrans = table_exp{N,18}*pixeltocmratioX;
    Ytrans = table_exp{N,19}*pixeltocmratioY;
    Gain = table_exp{N,20};         %ratio
    feedIdx = table_exp{N,21};      %switch
    feedTime = table_exp{N,22};     %in sec
    partialIdx = table_exp{N,23};      %switch
    PartialfeedTime = table_exp{N,25};
    
    TargetJumpDist = table_exp{N,10}*pixeltocmratio;
    
    CursorDisappLength = table_exp{N,14}*pixeltocmratio;
    
    CursorAppLength = table_exp{N,15}*pixeltocmratio;
    
    CursorJumpDist = table_exp{N,16}*pixeltocmratio;
    
    PartialfeedDist = table_exp{N,24}*pixeltocmratio;
    
    SetMouse(xCenter-300,yCenter-100);
    HideCursor;
    flag = 0;
    ticStore = [];
    flag_CJ = 0;
    trans_flag = 0;
    
    
    while 1 && Translation==0
        [xCursor,yCursor] = GetMouse(wPtr);
        yCursor = (yCursor*1.5083)+ ScrCorrectfactory;
        xCursor = rect(3)-xCursor;
        xCursor = (xCursor*1.2893)+ScrCorrectfactorx;
        
        myRect = [xCursor - CursorWidth/2 , yCursor - CursorHeight/2 , ...
            xCursor + CursorWidth/2 , yCursor + CursorHeight/2];
       
        startCursorDist = sqrt((Sx-xCursor)^2 + (Sy-yCursor)^2);
        if startCursorDist < 2*pixeltocmratio
        Screen('FillOval',wPtr,CursorColor,myRect);
        end
        Screen('FillOval',wPtr,StartColor,StartRect(N,:));
        
        if (xCursor > StartRect(N,1)) && (xCursor < StartRect(N,3)) && ...
                (yCursor > StartRect(N,2)) && (yCursor < StartRect(N,4))
            
            ticStart = tic;
            ticStore = cat(1,ticStore,ticStart);
            
            timestamp = GetSecs;
            timestampTarget = 0;
            
            xCursor = rect(3) - xCursor;
            
            Data = [Data; timestamp timestampTarget IsRot IsTargetJump IsCursorJump IsTranslation IsGain ...
                xCursor yCursor xCursor yCursor];
            
            if toc(ticStore(1)) > startTime
                Screen('Flip', wPtr);
                
                if TargetJumpDist~=0 || (NextTarget==0)
                    Beeper(700,0.4,0.1);
                end
                break; %break out of the while loop and enter target reach loop
            end
        else
            ticStore = [];
            ticStore2 = [];
        end
        
        Screen('Flip', wPtr);
        
    end
    
    
    while 1 && Translation~=0
        IsTranslation = 1;
        
        [xHand,yHand] = GetMouse(wPtr);
        
        yHand = (yHand*1.5083)+ ScrCorrectfactory;
        xHand = rect(3)-xHand;
        xHand = (xHand*1.2893)+ScrCorrectfactorx;
        
        xCursor = xHand + Xtrans;
        yCursor = yHand + Ytrans;
        xCursor_handActual = xHand;
        yCursor_handActual = yHand;
        
        myRect = [xCursor - CursorWidth/2 , yCursor - CursorHeight/2 , ...
            xCursor + CursorWidth/2 , yCursor + CursorHeight/2];
        myRect_hand = [xHand - CursorWidth/2 , yHand - CursorHeight/2 , ...
            xHand + CursorWidth/2 , yHand + CursorHeight/2];
        
        startCursorDist = sqrt((Sx-xCursor)^2 + (Sy-yCursor)^2);
        if startCursorDist/pixeltocmratio < 3
            Screen('FillOval',wPtr,CursorColor,myRect);
        end 
        
        Screen('FillOval',wPtr,StartColor,StartRect(N,:));
        
        if (xCursor > StartRect(N,1)) && (xCursor < StartRect(N,3)) && ...
                (yCursor > StartRect(N,2)) && (yCursor < StartRect(N,4))
            ticStart = tic;
            ticStore = cat(1,ticStore,ticStart);
            IsTargetJump = 0;
            timestamp = GetSecs;
            timestampTarget = 0;
            
            xHand = rect(3) - xHand;
            xCursor = rect(3) - xCursor;
            
            Data = [Data; timestamp timestampTarget IsRot IsTargetJump IsCursorJump IsTranslation IsGain ...
                xHand yHand xCursor yCursor];
            
            if toc(ticStore(1)) > startTime
                Screen('Flip', wPtr);
                
                if TargetJumpDist~=0 || (NextTarget==0)
                    Beeper(700,0.4,0.1);
                end
                break; %break out of the while loop and enter target reach loop
            end
        else
            ticStore = [];
            ticStore2 = [];
        end
        
        Screen('Flip', wPtr);
    end
    
    
    [xHand,yHand] = GetMouse(wPtr);
    yHand = (yHand*1.5083)+ ScrCorrectfactory;
    xHand = rect(3)-xHand;
    xHand = (xHand*1.2893)+ScrCorrectfactorx;
    
    xCursor = xHand;
    yCursor = yHand;
    
    if Translation~=0
        IsTranslation = 1;
        xCursor = xHand + Xtrans;
        yCursor = yHand + Ytrans;
        xCursor_handActual = xHand;
        yCursor_handActual = yHand;
    end
    
    %             myRect = [xCursor - CursorWidth/2 , yCursor - CursorHeight/2 , ...
    %                     xCursor + CursorWidth/2 , yCursor + CursorHeight/2];
    %
    %             Screen('FillOval',wPtr,StartColor,StartRect);
    %             Screen('FillOval',wPtr,TargetColor,TargetRect(N,:));
    %             Screen('FillOval',wPtr,CursorColor,myRect);
    %             Screen('Flip', wPtr);
    %
    count = 1;
    count2 = 0.0;
    thress = 1.0;
    
    ticStart = tic;
    ticStore2 = cat(1,ticStore2,ticStart);
    
    ticStore = [];
    ticStart = tic;
    ticStore = cat(1,ticStore,ticStart);
    
    Final_point1 = (table_targets{1,10} - 0.2)*pixeltocmratio;
    Final_point2 = (table_targets{1,10} + 0.5)*pixeltocmratio;
    blueFlag = 0;
    
    while toc(ticStore2(1)) < RecordingTime
        
        [xHand,yHand] = GetMouse(wPtr);
        yHand = (yHand*1.5083)+ ScrCorrectfactory;
        xHand = rect(3)-xHand;
        xHand = (xHand*1.2893)+ScrCorrectfactorx;
        
        xCursor = xHand;
        yCursor = yHand;
        
        %%
        %-------------------------------------Catch Trials---------------------------
        
        if catchTrials(find(catchTrials==N))==N
            
            startCursorDist = sqrt((Sx-xCursor)^2 + (Sy-yCursor)^2);
            
            myRect = [xCursor - CursorWidth/2 , yCursor - CursorHeight/2 , ...
                xCursor + CursorWidth/2 , yCursor + CursorHeight/2];
            
            Screen('FillOval',wPtr,StartColor,StartRect(N,:));
            Screen('FillOval',wPtr,TargetColor,TargetRect(N,:));
            
            if feedIdx==0
                
            else
                Screen('FillOval',wPtr,CursorColor,myRect);     %veridical
            end
            
            Screen('Flip',wPtr);
            
        else
            
            if Translation~=0
                IsTranslation = 1;
                xCursor = xHand + Xtrans;
                yCursor = yHand + Ytrans;
                xCursor_handActual = xHand;
                yCursor_handActual = yHand;
            end
            
            [polTH,polM] = cart2pol((xCursor - Sx)/(100*pixeltocmratioX),(yCursor-Sy)/(100*pixeltocmratioY));
            
            if Gain~=0
                IsGain = Gain;
                polM = (Gain*polM);
            end
            
            if CursorRotation~=0
                IsRot = CursorRotation;
                theta = CursorRotation*(pi/180);
%                 polTH = polTH - theta;
                polTH = (180 + CursorRotation) * (pi/180); 

            end
            
            [xCursor, yCursor] = pol2cart(polTH, polM);
            xCursor = xCursor*100*pixeltocmratioX + Sx;
            yCursor = Sy + yCursor*100*pixeltocmratioY;
            
            
            
            startCursorDist = sqrt((Sx-xCursor)^2 + (Sy-yCursor)^2);
            
            
            %------------------TargetJump---------------------------
            %%
            if NextTarget~=0
                IsTargetJump = NextTarget;
                
                if TargetJumpDist~=0
                    if startCursorDist > TargetJumpDist
                        PointTx = rect(3)-table_targets{NextTarget,6};
                        PointTy = table_targets{NextTarget,7};
                        PointTW = table_targets{NextTarget,8}*pixeltocmratioX;
                        PointTH = table_targets{NextTarget,9}*pixeltocmratioY;
                        TargetRect(N,:) = [PointTx-PointTW/2 , PointTy-PointTH/2 , ...
                            PointTx+PointTW/2 , PointTy+PointTH/2];
                        [Tx,Ty] = RectCenter(TargetRect(N,:));
                    end
                    
                elseif TargetJumpTime~=0
                    
                    if toc(ticStore2(1))>TargetJumpTime
                        PointTx = rect(3)-table_targets{NextTarget,6};
                        PointTy = table_targets{NextTarget,7};
                        PointTW = table_targets{NextTarget,8}*pixeltocmratioX;
                        PointTH = table_targets{NextTarget,9}*pixeltocmratioY;
                        TargetRect(N,:) = [PointTx-PointTW/2 , PointTy-PointTH/2 , ...
                            PointTx+PointTW/2 , PointTy+PointTH/2];
                        [Tx,Ty] = RectCenter(TargetRect(N,:));
                    end
                    
                elseif count
                    for i=1:beep_number
                        Beeper(700,0.5,0.1)
                        WaitSecs(0.5)
                    end
                    count=0;
                    
                    PointTx = rect(3)-table_targets{NextTarget,6};
                    PointTy = table_targets{NextTarget,7};
                    PointTW = table_targets{NextTarget,8}*pixeltocmratioX;
                    PointTH = table_targets{NextTarget,9}*pixeltocmratioY;
                    TargetRect(N,:) = [PointTx-PointTW/2 , PointTy-PointTH/2 , ...
                        PointTx+PointTW/2 , PointTy+PointTH/2];
                    [Tx,Ty] = RectCenter(TargetRect(N,:));
                end
            end
            
            %%
            %------------------------Cursor Displacement---------------
            
            if CursorJumpDist~=0
                IsCursorJump = 1;
                
                if startCursorDist > CursorDisappLength && startCursorDist < CursorAppLength
                    
                    
                else
                    if startCursorDist >= CursorAppLength
                        
                        if flag_CJ == 0
                            syms cursX cursY
                            startX = Sx;
                            startY = Sy;
                            
                            cursX = xCursor;
                            cursY = yCursor;
                            
                            cursorToStartdist = CursorAppLength;
                            start_jumplocdist = sqrt(cursorToStartdist.^2 + CursorJumpDist.^2);
                            syms jumpX jumpY
                            [solx,soly] = solve(...
                                ((jumpX)-startX).^2 + ((jumpY)-startY).^2 == start_jumplocdist.^2, ...
                                ((jumpX)-cursX).^2 + ((jumpY)-cursY).^2 == CursorJumpDist.^2);
                            
                            solx1 = double(solx(1,1));
                            soly1 = double(soly(1,1));
                            solx2 = double(solx(2,1));
                            soly2 = double(soly(2,1));
                            
                            jumpXY1 = double([real(solx1) real(soly1)]);
                            jumpXY2 = double([real(solx2) real(soly2)]);
                            
                            anglejumpXY1 = 180 - atan2d(jumpXY1(2)-Sy,jumpXY1(1)-Sx)
                            anglejumpXY2 = 180 - atan2d(jumpXY2(2)-Sy,jumpXY2(1)-Sx)
                            angle_orig = atan2d(cursY,cursX);
                            
                            if anglejumpXY1>270 && anglejumpXY1<360
                                display('angle misconfigration of anglejumpXY1')
                            end
                            
                            if anglejumpXY2>270 && anglejumpXY2<360
                                display('angle misconfigration of anglejumpXY2')
                            end
                            
                            % Screen('DrawDots',wPtr,jumpXY1,30,[255,0,0]);
                            % Screen('DrawDots',wPtr,jumpXY2,30,[255,0,0]);
                            
                            angles = [anglejumpXY1,anglejumpXY2];
                            
                            if CursorJumpDist<0
                                
                                pos_side = max(anglejumpXY1,anglejumpXY2);
                                angleJumpIndex = (find(angles==pos_side));
                                if angleJumpIndex==1
                                    xCJump = jumpXY1(1,1);
                                    yCJump = jumpXY1(1,2);
                                elseif angleJumpIndex==2
                                    xCJump = jumpXY2(1,1);
                                    yCJump = jumpXY2(1,2);
                                end
                                
                            else
                                neg_side = min(anglejumpXY1,anglejumpXY2);
                                angleJumpIndex = (find(angles==neg_side));
                                if angleJumpIndex==1
                                    xCJump = jumpXY1(1,1);
                                    yCJump = jumpXY1(1,2);
                                elseif angleJumpIndex==2
                                    xCJump = jumpXY2(1,1);
                                    yCJump = jumpXY2(1,2);
                                end
                            end
                            
                            
                            xShift = -(xCursor - xCJump)
                            yShift = -(yCursor - yCJump)
                            
                            Shift = sqrt((xCJump - xCursor)^2 + (yCJump - yCursor)^2)
                            %                                 SetMouse(rect(3)-xCursor,yCursor)
                            flag_CJ = 1;
                            
                            xCursor = xCJump;
                            yCursor = yCJump;
                            
                        else
                            
                            xCursor = xCursor + xShift;
                            yCursor = yCursor + yShift;
                            
                            
                        end
                    end
                end
            end
            
            myRect = [xCursor - CursorWidth/2 , yCursor - CursorHeight/2 , ...
                xCursor + CursorWidth/2 , yCursor + CursorHeight/2];
            
            Screen('FillOval',wPtr,StartColor,StartRect(N,:));
            Screen('FillOval',wPtr,TargetColor,TargetRect(N,:));
            
            if CursorJumpDist~=0 && (startCursorDist > CursorDisappLength &&...
                    startCursorDist < CursorAppLength)
                
                %                 elseif CursorJumpDist~=0 && startCursorDist > CursorDisappLength
                %                     myRect2 = [(xCursor + xShift) - CursorWidth/2 , (yCursor + yShift) - CursorHeight/2 , ...
                %                                          (xCursor + xShift) + CursorWidth/2 , (yCursor + yShift) + CursorHeight/2];
                %                     Screen('FillOval',wPtr,CursorColor,myRect2);
                
            elseif CursorJumpDist~=0 && startCursorDist~=CursorDisappLength
                if Translation~=0
                    myRect_hand = [xHand - CursorWidth/2 , yHand - CursorHeight/2 , ...
                        xHand + CursorWidth/2 , yHand + CursorHeight/2];
                    %Screen('FillOval',wPtr,[255,0,0],myRect_hand); %actual hand position
                end
                
                if feedIdx==0
                    
                    
                else
                    Screen('FillOval',wPtr,CursorColor,myRect);     %veridical
                end
                
            elseif CursorJumpDist==0
                if Translation~=0
                    myRect_hand = [xHand - CursorWidth/2 , yHand - CursorHeight/2 , ...
                        xHand + CursorWidth/2 , yHand + CursorHeight/2];
                    %Screen('FillOval',wPtr,[255,0,0],myRect_hand); %actual hand position
                end
                
                if feedIdx==0
                    if partialIdx~=0
                        if (PartialfeedTime~=0 && toc(ticStore2(1))>PartialfeedTime) ||...
                                (PartialfeedDist~=0 && startCursorDist>PartialfeedDist)
                        else
                            Screen('FillOval',wPtr,CursorColor,myRect);
                        end
                    else
                        
                    end
                elseif feedIdx~=0 && partialIdx==0
                    Screen('FillOval',wPtr,CursorColor,myRect);     %veridical
                end
                
            end
            
%             if startCursorDist>Final_point1 && startCursorDist<Final_point2 && blueFlag == 0 && partialIdx~=0 %added the partialIdx condition to ensure no feedback condition
%                 blueFlag = 1;
%                 blueX = xCursor;
%                 blueY = yCursor;
%             end
            
            
%             if blueFlag==1
%                 blueRect = [blueX - CursorWidth/2 , blueY - CursorHeight/2 , ...
%                     blueX + CursorWidth/2 , blueY + CursorHeight/2];
%                 
% %                        if feedIdx==0
% %                ticStore34 = [];
% %     ticStart = tic;
% %     ticStore34 = cat(1,ticStore34,ticStart);
% % %     while toc(ticStore34(1)) < 0.150
% % %                    Screen('FillOval',wPtr,[0 0 255],blueRect);
% % %                     Screen('FillOval',wPtr,CursorColor,myRect);
% % %                end          
% %      end  
%             end 
%         Screen('FillOval',wPtr,StartColor,StartRect(N,:));
%         Screen('FillOval',wPtr,TargetColor,TargetRect(N,:));
%         if blueFlag == 1
%         Screen('FillOval',wPtr,CursorColor,blueRect);
%         end
            Screen('Flip',wPtr);
            
        end
        %%
        %------------------Calculations-------------------------
        
        timestamp = GetSecs;
        timestampTarget = 0;
        if (xCursor > TargetRect(N,1) ) && (xCursor < TargetRect(N,3)) && ...
                (yCursor > TargetRect(N,2) ) && (yCursor < TargetRect(N,4))
            timestamp = GetSecs;
            timestampTarget = 1;
            
        end
        
        
        cursor_targetDist(N) = sqrt((xCursor-Tx).^2 + (yCursor-Ty).^2);
        
        xHand = rect(3) - xHand;
        xCursor = rect(3) - xCursor;
        
        Data = [Data; timestamp timestampTarget IsRot IsTargetJump IsCursorJump IsTranslation IsGain...
            xHand yHand xCursor yCursor];
        
        %  dataPlot = [dataPlot; xCursor,yCursor];
        
    end
    
    str1='';
    str2='';
    str3='';
    str4='';
    str5='';
    
    if IsRot
        str1 = {'Rot '};
    end
    if IsTargetJump
        str2 = {'TargetJump '};
    end
    if IsCursorJump
        str3 = {'DoubleStep '};
    end
    if IsTranslation
        str4 = {'Translation '};
    end
    if IsGain
        str5 = {'Gain '};
    end
    
    strTitle = strcat(str1,str2,str3,str4,str5);
    
%     if feedIdx==0 && partialIdx==0
%         Screen('FillOval',wPtr,StartColor,StartRect(N,:));
%         Screen('FillOval',wPtr,TargetColor,TargetRect(N,:));
%         Screen('FillOval',wPtr,CursorColor,myRect);
%         Screen('Flip',wPtr);
%         pause(feedTime)
%     end
    
    TargetRadius = abs(TargetRect(N,1) - TargetRect(N,3))/2;
    
    if cursor_targetDist(N) < TargetRadius
        
        RPoint = 10;
        RPoint_str = '10';
        beepfreq = 600;
        
    elseif cursor_targetDist(N) < TargetRadius + 5
        
        RPoint = 5;
        RPoint_str = '5';
        beepfreq = 800;
        
    elseif (cursor_targetDist(N) < (TargetRadius + 10)) && (cursor_targetDist(N) > (TargetRadius + 5))
        
        RPoint = 1;
        RPoint_str = '1';
        beepfreq = 1000;
        
    elseif cursor_targetDist(N) >= (TargetRadius + 10)
        
        RPoint = 0;
        RPoint_str = '0';
        beepfreq = 1200;
    end
    
    Beeper(beepfreq)
%     
%     Totalpoint = Totalpoint + RPoint;
%     totrpoint = int2str(Totalpoint);
%     
%     textbox = Screen('TextBounds', wPtr, RPoint);
%     textbox = OffsetRect(textbox, 720, 300);
%     Screen('FillRect', wPtr, [0, 0, 0, 0], textbox);
%     [xc, yc] = RectCenter(textbox);
%     Screen('glPushMatrix', wPtr);
%     Screen('glTranslate', wPtr, xc, yc, 0);
%     Screen('glScale', wPtr, -1, 1, 1);
%     Screen('glTranslate', wPtr, -xc, -yc, 0);
%     Screen('DrawText', wPtr, RPoint_str, xCenter, 300, [255, 255, 255]);
%     Screen('DrawText', wPtr, 'Total Point: ', xCenter-470, 200, [255, 255, 255]);
%     Screen('DrawText', wPtr, totrpoint, xCenter-300, 200, [255, 255, 255]);
%     
%     Screen('glPopMatrix', wPtr);
%     Screen('Flip', wPtr);
    pause(1);
    
    
    dbase = strcat(subjectNum,'_',subjectHand,'_',...
        subjectCond,'_','Trial_',num2str(N),'.txt');
    
    outfile = fopen(dbase,'w');
    format = repmat('%.2f\t',1,11);
    finalFormat = strcat(format,'\r\n');
    trialdata = transpose(Data);
    fprintf(outfile, finalFormat, trialdata );
    
    
    %%
    %-----------Plots--------------------------------------------------
    
%     xgr = Data(:,8);
%     ygr = Data(:,9);
%     xgrC = Data(:,10);
%     ygrC = Data(:,11);
%     
%     %-------------Hand Path---------------
%     figure; plot(xgr,-ygr,'g')
%     hold on
%     plot(rect(3)-Sx,-Sy,'k*')
%     hold on
%     plot(rect(3)-Tx,-Ty,'r*')
%     
%     axis([0 1368 -768 0])
%     
%     %--------------Cursor Path--------------
%     
%     hold on; plot(xgrC,-ygrC,'r')
%     %                 hold on
%     %                 plot(rect(3)-Sx,-Sy,'k*')
%     %                 hold on
%     %                 plot(rect(3)-Tx,-Ty,'r*')
%     axis([0 1368 -768 0])
%     xlabel('x-Axis')
%     ylabel('y-Axis')
%     title(strTitle)
%     legend('hand positions','Start Point','Target Point','cursor positions')
    %-------------------------------------------------------------------
    
    
end


sca;

%%
%         %-----------Plots--------------------------------------------------
%
%         xgr = Data(:,8);
%         ygr = Data(:,9);
%         xgrC = Data(:,10);
%         ygrC = Data(:,11);
%
%         %-------------Hand Path---------------
%                 figure; plot(xgr,-ygr,'g')
%                 hold on
%                 plot(rect(3)-Sx,-Sy,'k*')
%                 hold on
%                 plot(rect(3)-Tx,-Ty,'r*')
%                 axis([0 1368 -768 0])
%
%         %--------------Cursor Path--------------
%
%                 hold on; plot(xgrC,-ygrC,'r')
%                 hold on
%                 plot(rect(3)-Sx,-Sy,'k*')
%                 hold on
%                 plot(rect(3)-Tx,-Ty,'r*')
%                 axis([0 1368 -768 0])
%
%-------------------------------------------------------------------

%%        pdist2(pt1.Position,pt2.Position)

for N=1:numberTrials
    dbase = strcat(subjectNum,'_',subjectHand,'_',...
        subjectCond,'_','Trial_',num2str(N));
    
    file = fopen(dbase,'r');
    T = readtable(dbase,'Delimiter','\t','ReadVariableNames',false);
    T.Properties.VariableNames = {'timeStamp','target_timestamp','Rotation','TargetJump',...
        'CursorJump','Translation','Gain','HandX','HandY','CursorX','CursorY'};
    writetable(T,strcat(dbase,'.xlsx'));
end