"""Cross-authority regression checks for origin content and faction names."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def load(path):
    return json.loads((ROOT / path).read_text())


import unittest

class OriginCanonTests(unittest.TestCase):
    def test_faction_authorities_agree(self):
        contract = load('data/production/canon_contract_v4_1.json')
        expected = {r['id']: r['display_name'] for r in contract['active_factions_future_domain']}
        lock = load('data/brand/canon_lock.json')
        actual = {r['sigla']: r['nome'] for r in lock['faccoes']}
        phase = load('data/factions/factions_v2.json')
        assert actual == expected
        assert {r['id']: r['display_name'] for r in phase['factions']} == expected

    def test_prologue_does_not_replace_five_adult_acts(self):
        acts = load('data/narrative/acts_v3.json')
        assert len(acts['acts']) == 5
        assert [s['id'] for s in acts['prologue']['stages']] == ['Z1', 'Z2', 'Z3', 'Z4', 'Z5']
        assert acts['prologue']['stages'][0]['reward_brl_per_delivery'] == 2
        recruitment = [(i, b) for i, a in enumerate(acts['acts']) for b in a['required_beats'] if b['id'] == 'vera_recruta']
        assert len(recruitment) == 1 and recruitment[0][0] == 1
        assert 'tinker_bell' in recruitment[0][1]['characters']

    def test_planned_bosses_do_not_promote_or_alias_existing_fighters(self):
        roster = load('data/combat/roster_v3.json')
        assert roster['count'] == len(roster['fighters']) == 17
        bosses = roster['territory_bosses']
        assert len(bosses) == len({b['content_id'] for b in bosses}) == 11
        assert all(b['runtime_status'] == 'planned' and b['shipping'] is False for b in bosses)
        assert all(b['escalada']['max_new_counter_per_rematch'] == 1 for b in bosses)
        assert 'tinker_bell' not in {b['content_id'] for b in bosses}
        assert 'tinker_bell' not in {b['possible_existing_id'] for b in bosses}

    def test_economy_is_separate_and_not_crypto(self):
        economy = load('data/brand/canon_lock.json')['economia']
        assert economy['principal'] == 'criacoin' and economy['rua'] == 'BRL'
        assert economy['conversion_rate'] is None and economy['blockchain'] is False

if __name__ == "__main__":
    unittest.main()
