using Microsoft.AspNetCore.Mvc;

namespace accountms.Controllers
{
    [ApiController]
    [ApiVersion("1.0")]
    [Route("api/v{version:apiVersion}/[controller]")]
    public class ApiKeysController : ControllerBase
    {
        // Mettre à jour la seed :
        private static readonly List<ApiKey> ApiKeys = new()
        {
            new ApiKey { ClientId = "client1", ClientSecret = "secret1", Name = "Test Key", Expiration = DateTimeOffset.UtcNow.AddYears(1) }
        };

        [HttpGet]
        public ActionResult<IEnumerable<ApiKey>> GetAll() => Ok(ApiKeys);

        [HttpGet("{id}")]
        public ActionResult<ApiKey> Get(int id)
        {
            var key = ApiKeys.FirstOrDefault(k => k.ClientId == id.ToString());
            return key is null ? NotFound() : Ok(key);
        }

        [HttpPost]
        public ActionResult<ApiKey> Create(ApiKey newKey)
        {
            newKey.ClientId = (ApiKeys.Count > 0 ? ApiKeys.Max(k => int.Parse(k.ClientId)) + 1 : 1).ToString();
            ApiKeys.Add(newKey);
            return CreatedAtAction(nameof(Get), new { id = newKey.ClientId }, newKey);
        }

        [HttpDelete("{id}")]
        public IActionResult Delete(int id)
        {
            var key = ApiKeys.FirstOrDefault(k => k.ClientId == id.ToString());
            if (key is null) return NotFound();
            ApiKeys.Remove(key);
            return NoContent();
        }
    }

    public class ApiKey
    {
        public string ClientId { get; set; } = string.Empty;
        public string ClientSecret { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public DateTimeOffset? Expiration { get; set; }
    }
}
