Config = Config or {}
Config.Identity = Config.Identity or {}

Config.Identity = {
  cidPrefix = '',
  cidStartingNumber = 10001,
  cidLength = 5,

  -- Set to true when using character-system resource (disables auto-CID generation)
  useCharacterSystem = true,

  starterItems = {
    {
      name = 'id_card',
      count = 1,
      metadata = function(pid, citizenid, charinfo)
        return {
          label = 'State Identification Card',
          description = 'Official Los Santos ID Card',
          info = {
            firstname = charinfo.firstname or 'Unknown',
            lastname = charinfo.lastname or 'Unknown',
            cid = citizenid,
            dob = charinfo.birthdate or '1990-01-01',
            issued = os.date('%Y-%m-%d')
          }
        }
      end
    }
  },

  stateBagKey = 'cid',
  eventOnReady = 'identity:client:cidReady',

  rateLimits = {
    requestCID = 10,
    requestCharInfo = 10
  }
}
