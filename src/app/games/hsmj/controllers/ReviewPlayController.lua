local ReviewPlayController = class("ReviewPlayController",  function()
    local node = display.newNode()
    node:setNodeEventEnabled(true)
    return node
end)

local FAST_BACK_STEPS = 5
local FAST_FORWARD_STEPS = 8
local TOTAL_SETUP  = 5 

function ReviewPlayController:ctor(data, hostPlayer)
    self.view_ = app:createConcreteView("review.PlayControllerView"):addTo(self)
    self.selfID_ = selfData:getUid()
    self.hostPlayer_ = hostPlayer
    self.gameData_ = {}
    for i,v in ipairs(data) do
        if (not v.msg.type or v.msg.type ~= "recv") and (v.cmd ~= COMMANDS.HS_MJ_PLAYER_PASS) then
            table.insert(self.gameData_,v)
        end
    end

    self.commandIndex_ = 1
    self.inPlaying_ = false
    self.view_:showPlay(self.inPlaying_)
    self.deleCommondList_ = {
        COMMANDS.HS_MJ_PLAYER_ENTER_ROOM,
        COMMANDS.HS_MJ_PLAYER_ENTER_ROOM,
        COMMANDS.HS_MJ_PLAYER_ENTER_ROOM,
        COMMANDS.HS_MJ_PLAYER_ENTER_ROOM,
        COMMANDS.HS_MJ_ROOM_INFO,
        COMMANDS.HS_MJ_DEAL_CARD,
        COMMANDS.HS_MJ_DEAL_CARD,
        COMMANDS.HS_MJ_DEAL_CARD,
        COMMANDS.HS_MJ_DEAL_CARD,
    }
end

function ReviewPlayController:filterCmd_()
    self.playerList_ = {}
    self.commondList_ = {}
    for i,v in ipairs(self.deleCommondList_) do
        for i,v in ipairs(self.gameData_) do
            if v.cmd == COMMANDS.HS_MJ_PLAYER_ENTER_ROOM then
                table.insert(self.playerList_, v)
                table.removebyvalue(self.gameData_, v)
                break
            elseif v.cmd == COMMANDS.HS_MJ_ROOM_INFO then
                table.insert(self.commondList_, clone(v))
                table.removebyvalue(self.gameData_, v)
            elseif v.cmd == COMMANDS.HS_MJ_DEAL_CARD then
                table.insert(self.commondList_, clone(v))
                table.removebyvalue(self.gameData_, v)
                break
            end
        end
    end
    self:setHostPlayer_(self.playerList_)
    for i=1, #self.playerList_ do
        table.insert(self.commondList_, 1, self.playerList_[i])
    end
    self:playersSitdown_()
end

function ReviewPlayController:playersSitdown_()
    for i,v in ipairs(self.commondList_) do
        self:dispatchCommand(clone(v))
    end
end

function ReviewPlayController:adjustSeatID(list)
    local ret = {}

    for i,v in ipairs(list) do
        if v.msg.uid ~= self.selfID_ then
            table.insert(ret, clone(v))
        end
    end

    for i,v in ipairs(list) do
        if v.msg.uid == self.selfID_ then
            table.insert(ret, clone(v))
            break
        end
    end
    return ret
end

function ReviewPlayController:setHostPlayer_(list)
    list = self:adjustSeatID(list)
    self.playerList_ = list
    -- dump(self.playerList_, "setHostPlayer_")
    for i,v in ipairs(list) do
        if v.msg.uid == self.selfID_ then
            self.hostPlayer_:setUid(v.msg.uid)
            self.hostPlayer_:setSeatID(v.msg.seatID)
            return list
        end
    end
    for i,v in ipairs(list) do
        if v.msg.seatID == 1 then
            self.hostPlayer_:setUid(v.msg.uid)
            self.hostPlayer_:setSeatID(v.msg.seatID)
            return
        end
    end
end

function ReviewPlayController:onEnter()
    local handlers = {
        {self.view_.FAST_BACK_EVENT, handler(self, self.onFastBackEvent_)},
        {self.view_.FAST_FORWARD_EVENT, handler(self, self.onFastForwardEvent_)},
        {self.view_.PAUSE_EVENT, handler(self, self.onPauseEvent_)},
        {self.view_.PLAY_EVENT, handler(self, self.onPlayEvent_)},
        {self.view_.RETURN_EVENT, handler(self, self.onReturnEvent_)},
    }
    gailun.EventUtils.create(self, self.view_, self, handlers)

    self:setInPlaying(true)
    -- self:calcTotalSteps_()
    self:filterCmd_()
    self.totalSteps_ = #self.gameData_
    FAST_BACK_STEPS = math.ceil(self.totalSteps_ / TOTAL_SETUP)
    self.currStep_ = 0
    self:setCurrStep_(self.currStep_)
    self:schedule(handler(self, self.onPlaySetup_), 0.5)
end

function ReviewPlayController:onExit()
    gailun.EventUtils.clear(self)
end

function ReviewPlayController:isGameStep_(command)
    if not command then
        return false
    end
    return table.indexof(step_commands, command.cmd) ~= false
end

function ReviewPlayController:calcTotalSteps_()
    local steps = 0
    for i,v in ipairs(self.gameData_) do
        if self:isGameStep_(v) then
            steps = steps + 1
        end
    end
end

function ReviewPlayController:onPlaySetup_()
    if not self.inPlaying_ then
        return
    end
    local command = self.gameData_[self.commandIndex_]
    if command then
        self:dispatchCommand(clone(command))
        self.commandIndex_ = self.commandIndex_ + 1
        self:incrCurrStep_()
    end
end

function ReviewPlayController:resetRoundStartIndex_()
    self.roundStartIndex_ = nil
end

function ReviewPlayController:dispatchCommand(command, dennyAnim)
    command.msg.isReview = true
    command.msg.isDown = true
    if dennyAnim then
        command.msg.dennyAnim = true
    end
    dataCenter:dispatchCommand(command)
end

function ReviewPlayController:incrCurrStep_()
    self:setCurrStep_(self.currStep_ + 1)
end

function ReviewPlayController:setCurrStep_(index)
    local index = math.min(self.totalSteps_, index)
    index = math.max(1, index)
    self.currStep_ = index
    self.view_:setProgress(self.totalSteps_, self.currStep_)
end

function ReviewPlayController:setInPlaying(flag)
    self.inPlaying_ = flag
    self.view_:showPlay(self.inPlaying_)
end

function ReviewPlayController:calcCommandIndexByStep_()
    local step = 0
    for i,v in ipairs(self.gameData_) do
        if step >= self.currStep_ then
            return i
        end
        if self:isGameStep_(v) then
            step = step + 1
        end
    end
    return #self.gameData_
end

function ReviewPlayController:updatePlayProgress_()
    self.commandIndex_ = self.currStep_
    for i = 1, self.commandIndex_ - 1 do
        local command = clone(self.gameData_[i])
        if command then
            command.msg.inFastMode = true
            self:dispatchCommand(command, true)  -- 阻止动画播放
        end
    end
    self:setInPlaying(true)
end

function ReviewPlayController:onFastBackEvent_(event)
    if self.currStep_ <= 1 then 
        self.currStep_ = 1
        return
    end
    self:getParent():resetPlayer()
    self:resetRoundStartIndex_()
    self:playersSitdown_()
    self:setCurrStep_(self.currStep_ - FAST_BACK_STEPS)
    self:updatePlayProgress_()
    self:setInPlaying(false)
end

function ReviewPlayController:onFastForwardEvent_(event)
    if self.currStep_ >= self.totalSteps_ then 
        self.currStep_ = self.totalSteps_
        return
    end
    self:getParent():resetPlayer()
    self:resetRoundStartIndex_()
    self:playersSitdown_()
    self:setCurrStep_(self.currStep_ + FAST_BACK_STEPS)
    self:updatePlayProgress_()
    self:setInPlaying(false)
end

function ReviewPlayController:onPauseEvent_(event)
    self:setInPlaying(false)
end

function ReviewPlayController:onPlayEvent_(event)
    self:setInPlaying(true)
end

function ReviewPlayController:onReturnEvent_(event)
    print("========ReviewPlayController=======")
    dataCenter:setRoomID(0)
    transition.stopTarget(self)
    app:popScene()
end

return ReviewPlayController
