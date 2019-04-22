local data = {
{
    cards = {
        {22, 22, 12, 15, 18, 38, 38, 25, 24, 32, 12, 12, 12},
        {},
        {},
        {},
        {13, 12}
    },
    dealer =1,
},
-- 2暗杠
{
    cards = {
        {21, 22, 25, 25, 25, 13, 14, 15, 37, 38, 39, 25, 26},
        {23},
        {21, 22, 31, 32, 33, 24, 25, 26, 37, 38, 39, 25, 25},
        {},
        {}
    },
    dealer = 1,
},

-- 3明杠
{
    cards = {
        {11,11},
        {11},
        {},
        {},
        {13, 14, 15, 16, 17, 11}
    },
    dealer =1,
},

-- 4胡牌 自摸
{
    cards = {
        {11, 11, 11, 12, 12, 12, 13, 13, 13, 15, 15, 14, 21},
        {21, 21, 21, 22, 22, 22, 23, 23, 23, 24, 24, 24, 25},
        {15},
        {25},
        {15}
    },
    dealer =1,
},

-- 5胡牌 放炮
{
    cards = {
        {11, 11, 11, 12, 12, 12, 13, 13, 13, 14, 14, 14, 15},
        {15},
        {},
        {},
        {}
    },
    dealer =1,
},

-- 6放杠
{
    cards = {
        {11, 11, 11, 12, 12, 12, 13, 13, 13, 14, 14, 14, 15},
        {11},
        {},
        {},
        {}
    },
    dealer =1,
},

-- 7抢杠胡
{
    cards = {
        {11, 11, 12, 12, 12, 13, 13, 13, 14, 14, 14, 15, 15},
        {11},
        {12, 13, 31, 31, 31, 32, 32, 32, 33, 33, 33, 34, 34},
        {},
        {15, 22, 22, 22, 22, 11}
    },
    dealer =1,
},

-- 8 七小对
{
    cards = {
        {11, 11, 12, 12, 13, 13, 14, 14, 15, 15, 16, 16, 17},
        {11},
        {12, 13, 31, 31, 31, 32, 32, 32, 33, 33, 33, 34, 34},
        {},
        {17, 22, 22, 22, 22, 11}
    },
    dealer =1,
},

-- 9 1红中胡
{
    cards = {
        {51, 11, 13, 12, 12, 13, 13, 13, 14, 14, 14, 15, 15},
        {},
        {},
        {},
        {15}
    },
    dealer =1,
},

-- 10 2红中胡
{
    cards = {
        {51, 11, 51, 12, 12, 13, 13, 13, 14, 14, 14, 15, 15},
        {11},
        {12, 13, 31, 31, 31, 32, 32, 32, 33, 33, 33, 34, 34},
        {},
        {15, 22, 22, 22, 22, 11}
    },
    dealer =1,
},

    -- 长沙麻将测试用例
    -- 11 听牌杠
    {
        cards = {
            {11,11,11,12,12,12,13,13,13,14,14,14,15},
            {},
            {},
            {},
            {11, 33, 34}
        },
        dealer =1,
    },
--12
    {
        cards = {
            {11, 11, 11, 11, 12, 12, 12, 12, 13, 14, 15, 15, 16},
            {22, 22 ,23, 23, 23, 23, 24, 24, 24, 24, 25, 25, 26},
            {26},
            {16},
            {16}
        },
        dealer =1,
    },
    -- 13 七小对
{
    cards = {
        {},
        {11, 11, 12, 12, 13, 13, 14, 14, 15, 15, 16, 16, 17},
        {},
        {},
        {18, 17}
    },
    dealer =1,
},
    -- 14 七小对
{
    cards = {
        {},
        {11, 11, 12, 12, 13, 13, 14, 14, 15, 15, 16, 16, 18},
        {19},
        {},
        {19, 17,18}
    },
    dealer =1,
},
    -- 15 清一色
{
    cards = {
        {19},
        {11, 11, 11, 12, 12, 12, 14, 14, 14, 15, 16, 17, 19},
        {18},
        {},
        {18, 17}
    },
    dealer =1,
},
    -- 16 将将胡
{
    cards = {
        {19},
        {15, 15, 22, 12, 12, 12, 35, 32, 35, 25, 28, 18, 18},
        {18},
        {},
        {18, 17}
    },
    dealer =1,
},

    -- 17  7小队
{ 
    cards = {
        {11, 11, 12, 12, 13, 13, 14, 14, 15, 15, 16, 16, 17},
        {21, 21, 22, 22, 23, 23, 24, 24, 25, 25, 26, 26, 27},
        {},
        {},
        {}
    },
    dealer = 2,
},

    -- 18  豪华七小对
{
    cards = {
        {11, 12, 13, 15, 15, 19, 16, 17, 18, 18, 18, 19, 19},
        {31, 21, 22, 23, 24, 25, 26, 26, 27, 28, 29, 29, 29},
        {},
        {},
        {18}
    },
    dealer = 1,
},

    -- 19  三同
{
    cards = {
        {11, 11, 11, 12, 12, 12, 13, 14, 15, 16, 17, 18, 19},
        {21,21,21,22,23,24,25,26,27,28,29,29,29},
        {},
        {},
        {12,11}
    },
    dealer = 3,
},

    -- 20  三同
{
    cards = {
        {25},
        {19},
        {11, 11, 11, 26, 26, 26, 19},
        {},
        {15,12,11,22,33}
    },
    dealer = 1,
},

}

return data