local PaperCardGroup = require("app.games.sybp.utils.PaperCardGroup")
local PaperCardList = class("PaperCardList", gailun.BaseView)
local FaceAnimationsData = require("app.data.FaceAnimationsData")
local POKER_WIDTH = 124
local SELECTED_HEIGHT = 40

local KAN_AP_X = 0.5 -- 坎的X锚点
local KAN_AP_Y = 0 -- 坎的Y锚点
local KAN_Y = -160 -- 坎的坐标位置
local THREWLINE_Y = 650

local SHOW_RAW_CARD_SECONDS = 0.05 -- 单张牌的显示间隔时间
local RAW_MOVE_OUT_SECONDS = 0.2 -- 向两边扩张的时间
local RAW_MOVE_BACK_SECONDS = 0.4 -- 回收的时间
local KAN_CARDS_SPACE_SECONDS = 0.0 -- 中间合并完成后重新排序前的等待时间
local MO_PAI_REORDER_SECONDS = 0.2 -- 摸牌的展开与排序时间

local posOfTableRate = {{display.cx - 25 * 3, display.height * 0.53}, {15, -156}, {-10, -158}}
local posOfTrashView = {{display.right - 30, display.height * 0.46}, {40, -94}, {-40, -94}}

local out_posy = display.cy + 25
local iconHand_posx = display.cx

local max_kan = 9

local TYPES = gailun.TYPES
local nodeOperate = {
    type = TYPES.ROOT,
    children = {
        {type = TYPES.NODE, var = "nodePaperCards_"},  
        {type = TYPES.NODE, var = "nodeOperate_"},
        {type = TYPES.NODE, var = "nodeAni_"},
        {type = TYPES.LABEL, var = "lblhuadong_", visible = false, options = {text="滑动到线外出牌", size=30, font = DEFAULT_FONT },ap = {0.5, 0}, x = display.cx, y = out_posy},

    }
}

function PaperCardList:ctor()
    self.margin_ = 90
	self.tempCards_ = {}
	self.isInReView_ = false
    self.showCards_ = {}
	self.kans_ = {}
    self.handCards_ = {}
    self.selectCard = nil
    self.doneOperate_ = false
    self.inFastMode_ = false
    self:onEnter()
    if setData:getCDPHZCardSize() == 2 then
        out_posy = display.cy + 50
    elseif setData:getCDPHZCardSize() == 1 then
        out_posy = display.cy - 20
    else
        out_posy = display.cy + 25
    end
end

function PaperCardList:setPlayer(player)
    self.player_ = player
end

function PaperCardList:getCardsNode()
    local nodes = {}
    for _, v in ipairs(self.kans_) do
        gailun.utils.extends(nodes, v:getCardsNodeList())
    end
    return nodes
end

function PaperCardList:setPlayerView(playerView)
    self.playerView_ = playerView
end

function PaperCardList:onEnter()
    local handlers = {
        {app.BACK_GROUND_EVENT, handler(self, self.onBackGroundEvent_)},
    }
    gailun.EventUtils.create(self, app, self, handlers)
    gailun.uihelper.render(self, nodeOperate)
end

function PaperCardList:setInReView(bool)
	self.isInReView_ = bool
    self.inFastMode_ = bool

end
 
function PaperCardList:shouzhang(card, isReview)
    -- if isReview then
    table.insert(self.handCards_, card)
    -- end
    self:showPaperCardsWithoutAnim_(self.handCards_, callfunc)
end

function PaperCardList:turnToOut()
    self.doneOperate_ = false
    self:performWithDelay(function ()
        if not self.doneOperate_ then
            self:showOutCardTip()
        end
    end, 2)
end

function PaperCardList:dealCards(cards, callfunc)
    if not cards or 0 == #cards then
        return
    end
    self:removeAllPokers()
    self.sortIndex_ = 1
    self.handCards_ = cards   
    self:showPaperCardsWithoutAnim_(cards, callfunc, isRconnect)
end

function PaperCardList:showPokers(cards, callfunc, isRconnect)
	if not cards or 0 == #cards then
        return
    end
    self:removeAllPokers()
	self.sortIndex_ = 1
    self.handCards_ = cards
	self:showPaperCardsWithoutAnim_(cards, callfunc, isRconnect)
end

function PaperCardList:calcPokerPos_(total, index)
    
    if setData:getCDPHZCardSize() == 2 then
        self.margin_ = 90+3
    elseif setData:getCDPHZCardSize() == 1 then
        self.margin_ = 68+3
    else
        self.margin_ = 75+3
    end
	local offset = (index - (total - 1) / 2 - 1) * self.margin_
	local x = display.cx + offset
    local y = -110+78
    if setData:getCDPHZCardSize() == 1 then
        y = -110+82
    end
    if setData:getCDPHZCardType() == 1 then
        y = y - 50
        if setData:getCDPHZCardSize() == 1 then
            y = y + 5
        end
    end
    if setData:getCDPHZCardSize() == 2 then
        y = -110+10
        if setData:getCDPHZCardType() == 2 then
            y = -110+70
        end
    end
	return x, y, index
end

function PaperCardList:getCards_()
	local cards = {}
	local nodes = self:getChildren()
	for _,v in pairs(nodes) do
		table.insert(cards, v:getCard())
	end
	return cards
end
 
function PaperCardList:showPaperCardsWithAnim_(cards, callfunc)
    self:removeAllPokers()
    self.handCards_ = cards
    if not cards then
        return
    end
    local kanList = PaperCardGroup.clacKanList(cards)
    local total_count = table.nums(kanList)
    local p = self:convertToNodeSpace(cc.p(display.cx, KAN_Y))
    for k = 1, total_count do
        local x, y = self:getKanPos(total_count, k, #kanList[k])
        local p2 = self:convertToNodeSpace(cc.p(x, y))
        local tmp = app:createConcreteView("KanView", kanList[k], handler(self, self.onTouchCards), true,k * 0.08,true):addTo(self.nodePaperCards_):pos(p.x, p2.y)
        tmp:setAnchorPoint(cc.p(KAN_AP_X, KAN_AP_Y))
        table.insert(self.kans_, tmp)
    end
    self:pauseTouchOfKans() --先暂停坎的触摸 
    self:spreadAllKan(MO_PAI_REORDER_SECONDS)
    self:updateTotalHuXi()
    self:performWithDelay(function ()
        self:resumeTouchOfKans()
    end, MO_PAI_REORDER_SECONDS * (#self.kans_ + 1) / 2)
    return self
end

function PaperCardList:showPaperCardsWithoutAnim_(cards, callfunc, isRconnect)
    self:removeAllPokers()
    self.handCards_ = cards
    local kanList = PaperCardGroup.clacKanList(cards)
    local total_count = #kanList
    local p = self:convertToNodeSpace(cc.p(display.cx, KAN_Y))
    for k = 1, total_count do
        local x, y = self:calcPokerPos_(total_count, k, #kanList[k])
        local p2 = self:convertToNodeSpace(cc.p(x, y))
        local tmp = app:createConcreteView("KanView", kanList[k], handler(self, self.onTouchCards), false,0,false):addTo(self.nodePaperCards_)
        tmp:setAnchorPoint(cc.p(KAN_AP_X, KAN_AP_Y))
        tmp:pos(x,y)
        if setData:getCDPHZCardSize() == 2 then

        elseif setData:getCDPHZCardSize() == 1 then
            tmp:setScale(0.75)
        else
            tmp:setScale(0.85)
        end
        table.insert(self.kans_, tmp)
    end
    self:pauseTouchOfKans() --先暂停坎的触摸 
    -- self:spreadAllKan(MO_PAI_REORDER_SECONDS)
    self:updateTotalHuXi()
    self:performWithDelay(function ()
        self:resumeTouchOfKans()
    end, MO_PAI_REORDER_SECONDS * (#self.kans_ + 1) / 2)
    return self
end

local GAME_SCENE_OFFSET_X = 0
-- 计算组牌的坐标
function PaperCardList:getKanPos(total_count, index, cards_num)
    --X的起始值，Y的初始值,两列牌之间的距离，两列牌之间的最大距离
    local x, y = display.cx , KAN_Y, 170
    local pos = index - (total_count + 1.0) / 2
    return x, y, pos * 5.35
end

-- 计算初始牌的坐标
function PaperCardList:getRawCardX(total_count, index)
    local pos, space = index - (total_count + 1.0) / 2, 80
    local x = display.cx + pos * space
    return x
end

-- 按原始顺序显示收到的牌
function PaperCardList:showRawCards(cards, index, callback)
    local index = index or 1
    local kan_num = math.ceil(#cards / 3)
    local x = self:getRawCardX(kan_num, math.ceil(index / 3))
    local y = 296 - ((index - 1) % 3) * 70
    local p = self:convertToNodeSpace(cc.p(x, y))
	local tmp = app:createConcreteView("pingPu.PaperCardView", cards[index], 2, false, nil):addTo(self):pos(p.x, p.y, 100)

 	tmp:fanPai() 
    table.insert(self.showCards_, tmp)

    if index >= #cards then
        return callback()
    end

    return self:performWithDelay(function ()
        self:showRawCards(cards, index + 1, callback)
    end, SHOW_RAW_CARD_SECONDS)
end

-- 合并牌到一起
function PaperCardList:heBingCards(cards, callback)
    local x, y = display.cx, 170
    local p = self:convertToNodeSpace(cc.p(x, y))
    for k,v in pairs(cards) do
        if v then
        local index = math.ceil(k / 3)
            local zhongKanIndex = (index - 4)
            local moveX = zhongKanIndex * 10
            local moveY = 0--((k - 1) % 3 - 1) * -60
            transition.moveBy(v, {x = moveX, y = moveY, time = RAW_MOVE_OUT_SECONDS})
            self:performWithDelay(function ()
                local _, rawy = v:getPosition()
                transition.moveTo(v, {x = p.x, y = rawy, time = RAW_MOVE_BACK_SECONDS})
            end, RAW_MOVE_OUT_SECONDS)
        end
        
    end

    local seconds = RAW_MOVE_OUT_SECONDS + RAW_MOVE_BACK_SECONDS + KAN_CARDS_SPACE_SECONDS
    self:performWithDelay(callback, seconds)
end

function PaperCardList:showKanCards(cards)
    local cards = PaperCardGroup.chaiPai(cards)
    local total_count = table.nums(cards)
    local p = self:convertToNodeSpace(cc.p(display.cx, KAN_Y))
    for k = 1, total_count do
        local x, y = self:getKanPos(total_count, k, #cards[k])
        local p2 = self:convertToNodeSpace(cc.p(x, y))
		local tmp = app:createConcreteView("KanView", cards[k], handler(self, self.onTouchCards), true):addTo(self.nodePaperCards_):pos(p.x, p2.y)
        tmp:setAnchorPoint(cc.p(KAN_AP_X, KAN_AP_Y))
        if setData:getCDPHZCardSize() == 2 then
        elseif setData:getCDPHZCardSize() == 1 then
            tmp:setScale(0.75)
        else
            tmp:setScale(0.85)
        end
        table.insert(self.kans_, tmp)
    end

    for k,v in pairs(self.showCards_) do --移除所有的显示的牌
        if v then
            v:removeSelf()--todo
        end
    end
    self.showCards_ = {}

    self:pauseTouchOfKans() --先暂停坎的触摸 
    self:spreadAllKan(MO_PAI_REORDER_SECONDS)
    self:updateTotalHuXi()
    self:performWithDelay(function ()
        self:resumeTouchOfKans()
    end, MO_PAI_REORDER_SECONDS * (#self.kans_ + 1) / 2)
    return self
end

function PaperCardList:flipAllCards(cards)
    local cards = PaperCardGroup.chaiPai(clone(cards))
    local deltaTime = 0.05
    local total_count = table.nums(cards)
    for k = 1, total_count do
        local x, y, rotateValue = self:calcPokerPos_(total_count, k)
        local p = self:convertToNodeSpace(cc.p(x, y))
        local tmp = KanView.new(cards[k], handler(self, self.onTouchCards)):addTo(self):pos(p.x, p.y)
        table.insert(self.kans_, tmp)
        tmp:setAnchorPoint(cc.p(KAN_AP_X, KAN_AP_Y))
    end

    self:pauseTouchOfKans() --先暂停坎的触摸
    self:performWithDelay(handler(self, self.resumeTouchOfKans), 1.5)
    self:updateTotalHuXi()
    return self
end

function PaperCardList:updateTotalHuXi()
    if not self.progressHuXi then
        return
    end
    self:performWithDelay(function ()
        local total_huxi = self.tableRate.rate
        for i, v in ipairs(self.kans_) do
            local cards = v:getCards()
            total_huxi = total_huxi + PaperCardRule.calcThreeHuXi(cards)
        end
        self.progressHuXi:setHuXi(total_huxi)
    end, 0.1)
end


-- 停止所有牌的触摸响应
function PaperCardList:pauseTouchOfKans()
    for i, v in ipairs(self.kans_) do
        for k, v2 in pairs(v:getSprites()) do
            v2:setTouchEnabled(false)
        end
    end
end

-- 恢复所有坎的触摸
function PaperCardList:resumeTouchOfKans()
    for i, v in ipairs(self.kans_) do
        for k, v2 in pairs(v:getSprites()) do
            v2:setTouchEnabled(true)
        end
        v:fixTiOrWei()
    end
end

-- 初始时分的所有坎匀速移动
function PaperCardList:spreadAllKan(seconds)
    self:reOrderAllKan(0.001, true)
end
 

function PaperCardList:removeHandCards(cards)
    for i,v in ipairs(cards) do
        local values = table.values(self.kans_)
        for i= #values,1,-1 do
            if values[i]:delCard(v) then
                break -- 防止多删
            end
        end
        table.removebyvalue(self.handCards_, v)
    end 
    self:reOrderAllKan()  
end 

function PaperCardList:removeCard(delCard,selectdedfirst)
    if selectdedfirst and self.selectCard ~= nil  then
        if self.selectCard.card == delCard then 
            self.selectCard:removeFromParent()
            self:reOrderAllKan() 
            self.selectCard = nil
        end
    else
        for k, v in pairs(self.kans_) do -- 移除空节点
            if v:delCard(delCard) then
                self:reOrderAllKan() 
                return true
            end
        end
    end
    table.removebyvalue(self.handCards_, delCard)
    return false
end 

function PaperCardList:removeEmptyKans()
    for k, v in pairs(self.kans_) do -- 移除空节点
        if #v:getCards() <= 0 then
            v:removeAll()
            self:removeChild(v)
            table.remove(self.kans_, k)
            return self:removeEmptyKans()
        end
    end
end

-- 删除牌后整动所有列
function PaperCardList:reOrderAllKan(seconds, oneByOne, otherKan, origPos)
    self:removeEmptyKans()
    local seconds = seconds or 0.2
    local total_count = #self.kans_

    local handCards = {}
    local cards = {}
    for i, v in ipairs(self.kans_) do
        local count = #v:getCards()
        handCards[i] = clone(v:getCards())
        for j=1, count do
            table.insert(cards, handCards[i][j])
        end
        local x, y = self:calcPokerPos_(total_count, i)
        local p = self:convertToNodeSpace(cc.p(x, y))
        if origPos and otherKan and otherKan == v then
            v:setPosition(x, y)
            if otherKan and origPos then
                otherKan:showAddCard(origPos)
            end
        else
            transition.moveTo(v, {x = p.x, y = p.y, time = seconds})
            v:sortCardsByY(self.inFastMode_)
        end
        local rotate_seconds = seconds
        if oneByOne then
            local pos = i - (total_count + 1.0) / 2
            rotate_seconds = seconds * math.abs(pos)
        end
    end
    local consumer_handCards = {handCards = handCards, cards = cards, effective = 1}
    consumer_handCards = json.encode(consumer_handCards)
    gameConfig:set(CONSUMER_HANDCARDS, consumer_handCards)
end

function PaperCardList:notifyNotInKans()
    for i,v in ipairs(self.kans_) do
        v:hideTip()
    end
end

function PaperCardList:showThrowCardLine(bshow)
    if self.player_:isHostPlayer() and not self.player_:isOutCarding() then
        return
    end
    self.outTipLine_ = ccui.ImageView:create("res/images/paohuzi/game/line.png")
    local locX,locY = display.cx, out_posy 
    self.outTipLine_:setPosition(cc.p(locX, locY))  
    self.outTipLine_:setOpacity(30)
    self.nodeOperate_:addChild(self.outTipLine_,102)
    self.lblhuadong_:setVisible(true)
    self.lblhuadong_:setPositionY(out_posy)
end

function PaperCardList:hideOutCardTip(event)
    self.nodeAni_:removeAllChildren()
end

function PaperCardList:showOutCardTip(event)
    if display.getRunningScene().__cname == "ZhanJiScene" then
        return
    end
    local animaData = FaceAnimationsData.getCocosAnimation(44)
    gameAnim.createCocosAnimations(animaData, self.nodeAni_)
end


function PaperCardList:clearOperate(event)
    self.nodeOperate_:removeAllChildren()
    self.lblhuadong_:setVisible(false)
    for i,v in ipairs(self.kans_) do
        v:clearFromBack()
    end
end

function PaperCardList:onBackGroundEvent_(event)
    self:clearOperate()
end

function PaperCardList:changeKanCard(toObj, fromObj)
    local from_kan = fromObj:getParent()
    local from_card = fromObj.card
    local to_kan = toObj:getParent()
    local to_card = toObj.card
    local tx,ty = toObj:getPosition()
    local fx,fy = fromObj:getPosition()
    if to_kan and from_kan and toObj ~= fromObj then
        if from_kan:delTarget(fromObj) then 
            local pos = cc.p(tx,ty)
            to_kan:addCard(from_card, pos.x, pos.y)
        end
        if to_kan:delTarget(toObj) then 
            local pos = cc.p(fx,fy)
            from_kan:addCard(to_card, pos.x, pos.y)
        end
        self:reOrderAllKan()
        self:updateTotalHuXi()
        return true
    end
    return false
end

--跑胡子触摸事件
function PaperCardList:onTouchCards(obj, event, x, y)
    local p = self:convertToNodeSpace(cc.p(x, y))
    if event.name == 'began' then 
        self:clearOperate()
        self:hideOutCardTip()
        self.doneOperate_ = true
        self.tipCard_ = app:createConcreteView("pingPu.PaperCardView", obj.card, 2, false, nil):addTo(self.nodeOperate_):pos(p.x, p.y, 100)
        self.tipCard_:saveRawPosition() 
        if setData:getCDPHZCardSize() == 2 then
        elseif setData:getCDPHZCardSize() == 1 then
            self.tipCard_:setScale(0.75)
        else
            self.tipCard_:setScale(0.85)
        end
        obj:setOpacity(100)
        self.player_:showHightLight(obj.card,true)
        self:showThrowCardLine(true)
        if self.player_:isHostPlayer() and self.player_:isOutCarding() then
            display.getRunningScene():checkHu(obj:getCard())
        end
    elseif event.name == 'moved' then 
        if self.tipCard_ then
            self.tipCard_:pos(p.x, p.y)
        end
    else 
        obj:setOpacity(255)
        if self.player_:isHostPlayer() and self.player_:isOutCarding() then
            display.getRunningScene():checkHu(nil, true)
        end
        if self.tipCard_ then
            local tipRawX, tipRawY = self.tipCard_:getPosition() 
            self:clearOperate()
            self.player_:showHightLight(obj.card,false)
            if y > out_posy then --出牌的操作
                return self:onCardThrow(obj, x, y)
            end
            for i,v in ipairs(self.kans_) do
                if not v:isFixed() then
                    local result,toObj = v:isInKanCard(x, y)
                    if result then
                        if self:changeKanCard(toObj, obj) then
                            dump("XXXXXXXXXX222222")
                            return
                        end
                    end
    	            if v:isInKan(x, y) then 
                        self:onTouchBetweenKans(v, obj, x, y, tipRawY)
                        if self.player_:isHostPlayer() and self.player_:isOutCarding() then
                            self.playerView_:checkQuicklyTing(true)
                        end
                        dump("XXXXXXXXXX33333")
                        return
    	            end
            	end 
            end 
            dump("XXXXXXXXXX44444")
            self:onTouchOutAllKans(obj, x, y)
            if self.player_:isHostPlayer() and self.player_:isOutCarding() then
                self.playerView_:checkQuicklyTing(true)
            end
            return
        else
            self:clearOperate()
        end
    end
end

function PaperCardList:onTouchInSelfKan(kan, obj, point)
    local p = kan:convertToNodeSpace(cc.p(point.x, point.y))
    local x1, y1 = obj:getPosition()
    if p.y > y1 then
        obj:pos(x1, y1+1)
    else
        obj:pos(x1, y1-1)
    end
    kan:sortCardsByY()
end

-- 在某两坎之间移动
function PaperCardList:onTouchBetweenKans(to_kan, obj, x, y, tipRawY)
    local p = self:convertToNodeSpace(cc.p(x, y))
    local deltaY = p.y - tipRawY

    if to_kan:isFixed() then
        return
    end
    if obj:getParent() == to_kan then
        self:onTouchInSelfKan(to_kan, obj, p) 
        return
    end
    if not to_kan:canAddCard() then 
        return
    end

    local x1, y1 = obj:getPosition() 
    local card = obj.card
    if obj:getParent():delTarget(obj) then 
        local pos = to_kan:convertToNodeSpace(cc.p(x, y))
        to_kan:addCard(card, pos.x, pos.y)
    end
    self:reOrderAllKan()
    self:updateTotalHuXi()
end

-- 当前移动的牌未在所有坎之外
function PaperCardList:onTouchOutAllKans(obj, x, y)
    local kan = obj:getParent()   
    local count = #self.kans_
    if count <= max_kan then
        local p = self:convertToNodeSpace(cc.p(x, y))
        local currentIndex = self:clacCurrKanPos_(count,p.x)
        local x2, y2 = self:getKanPos(currentIndex, currentIndex)
        local p2 = self:convertToNodeSpace(cc.p(x2, y2))
        kan = app:createConcreteView("KanView",{}, handler(self, self.onTouchCards), true):addTo(self.nodePaperCards_)
        :pos(p.x, p2.y) 
        if setData:getCDPHZCardSize() == 2 then
        elseif setData:getCDPHZCardSize() == 1 then
            kan:setScale(0.75)
        else
            kan:setScale(0.85)
        end
        kan:setAnchorPoint(cc.p(KAN_AP_X, KAN_AP_Y))
        table.insert(self.kans_,currentIndex,kan)
    end
    local card = obj.card
    local origPos = 
    {
        x = x,
        y = y,
    }
    if obj:getParent():delTarget(obj) then
        local pos = kan:convertToNodeSpace(cc.p(x, y))
        kan:addCard(card,pos.x,pos.y)
        if count <= max_kan then
            kan:hide()
        end
    end
    if count <= max_kan then
        self:reOrderAllKan(nil,nil,kan,origPos)
    else
        self:reOrderAllKan()
    end
   
end

function PaperCardList:clacCurrKanPos_(count,x)
    local x1,y1 = self:getKanPos(count, count)
    print("======x1,y1==============",x1,x)
    if x > x1 then
        return count + 1
    else
        return 1
    end
end

function PaperCardList:tiPai()
    self:showPaperCardsWithoutAnim_(clone(self.handCards_))
end

function PaperCardList:showHightLight(card,isHigh)
    for _,v in ipairs(self.kans_) do
        v:showHightLight(card,isHigh) 
    end
end

function PaperCardList:fanPai()
	local nodes = self:getChildren()
	for _,v in pairs(nodes) do
		v:fanPai()
	end
end

function PaperCardList:pokersSort()
	local cards = self:getCards_()
	if not cards or #cards < 1 then
		return
	end
	local tempCards = self:sortChange_(cards)
	self:adjustPokerPos_(tempCards)
end

function PaperCardList:onCardThrow(obj, x, y)
    local rawX,rwaY = obj:getPosition()
    local pos = obj:getParent():convertToNodeSpace(cc.p(x, y))
    obj:setPosition(pos.x, pos.y)
    -- transition.moveTo(obj, {x = rawX, y = rwaY, time = 0.2, onComplete = function()

    -- end})	
    obj:setPosition(rawX, rwaY)
    if display.getRunningScene():getTable():isTianHuStart() then
        return
    end
    if self.player_:isHostPlayer() and not self.player_:isOutCarding() then
        return
    end
	obj:show()
    self.selectCard = obj
    local data = {cards = obj.card}
    dataCenter:sendOverSocket(COMMANDS.SYBP_CHU_PAI, data)

    local tableController = display.getRunningScene().tableController_
    local data = {}
    data.code = 0
    data.cards = obj.card
    data.operates = {}
    data.seatID = self.player_:getSeatID()
    tableController:doPlayerChuPai(data)
end

function PaperCardList:sortChange_(cards)
    return cards
end

function PaperCardList:removeAllPokers()
    -- print("removeAllPokers()"..self.player_:getSeatID())
    local cards = nil 
    self.handCards_ = {}
    self.showCards_ = {}
	self.nodePaperCards_:removeAllChildren()
    self.kans_ = {}
    self:clearOperate()
    self:hideOutCardTip()
end

function PaperCardList:changeHandCard()
    print("···..PaperCardList:changeHandCard()....")
    self:showPokers(clone(self.handCards_))
end

return PaperCardList 
