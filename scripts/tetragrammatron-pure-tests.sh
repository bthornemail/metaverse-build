#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

python3 -m unittest \
  runtime.tetragrammatron.tests.test_pure_and_router \
  runtime.tetragrammatron.tests.test_xml_projection \
  runtime.tetragrammatron.tests.test_projective_time \
  runtime.tetragrammatron.tests.test_p_adic_time \
  runtime.tetragrammatron.tests.test_projective_report_schema \
  runtime.tetragrammatron.tests.test_klein_blackboard \
  runtime.tetragrammatron.tests.test_klein_incidence \
  runtime.tetragrammatron.tests.test_ast_spherepack \
  runtime.tetragrammatron.tests.test_kgc \
  runtime.tetragrammatron.tests.test_agent_lifecycle \
  runtime.tetragrammatron.tests.test_reversible_time \
  runtime.tetragrammatron.tests.test_perles_identity \
  runtime.tetragrammatron.tests.test_light_garden_sphere \
  runtime.tetragrammatron.tests.test_fano_scheduler \
  runtime.tetragrammatron.tests.test_control_superposition \
  runtime.tetragrammatron.tests.test_living_xml \
  runtime.tetragrammatron.tests.test_living_xml_fuzz \
  runtime.tetragrammatron.tests.test_agent_memory \
  runtime.tetragrammatron.tests.test_semantic_identity \
  runtime.tetragrammatron.tests.test_identity_occurrence \
  runtime.tetragrammatron.tests.test_seed_algebra \
  runtime.tetragrammatron.tests.test_seed_companion \
  runtime.tetragrammatron.tests.test_lane16

echo "ok tetragrammatron pure control-code tests"
