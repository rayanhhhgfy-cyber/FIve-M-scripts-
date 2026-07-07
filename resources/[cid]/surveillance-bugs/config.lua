Config = Config or {}
Config.SurveillanceBugs = Config.SurveillanceBugs or {}

Config.SurveillanceBugs = {
    AllowedJobs = { 'cid' },
    MinRank = 0,
    DeployDuration = 3000,
    FeedRefreshInterval = 2000,
    MaxActiveBugsPerPlayer = 10,

    BugTypes = {
        surveillance_camera = {
            label = 'Pen Camera',
            item = 'surveillance_camera',
            duration = 172800,
            hasFeed = true,
            feedType = 'image',
        },
        audio_bug = {
            label = 'Audio Bug',
            item = 'audio_bug',
            duration = 259200,
            hasFeed = true,
            feedType = 'audio',
        },
        gps_tracker = {
            label = 'GPS Tracker',
            item = 'gps_tracker',
            duration = -1,
            hasFeed = true,
            feedType = 'gps',
        },
    },

    BugTargetModels = {
        'prop_cs_cardbox_01',
        'prop_sec_barier_02a',
        'prop_sec_barier_02b',
        'v_ilev_ph_gendoor',
        'v_ilev_ph_gendoor2',
        'prop_phone_ing_02',
        'prop_phone_ing_03',
    },
}
