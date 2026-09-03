Resonance Leave — RAP + Fiori Rebuild
Rebuilding a Burnout-Detection Engine on the ABAP RESTful Application Programming Model
<aside> 💡

Stack: SAP BTP ABAP Environment (Steampunk/cloud) · RAP (Managed BO) · CDS Views · Behavior Definitions · Fiori Elements List Report · ABAP Cloud

Module: HCM — Human Capital Management

Type: Independent portfolio project · Solo · Rebuild of an original ECC/classic ABAP project

Status: Backend + Fiori List Report complete ✓ (Steps 1–6 of 7)

System: SAP BTP ABAP Environment trial · Package ZRESONANCE

</aside>

A cloud-native rebuild of an SAP ECC burnout-detection and smart-coverage system — proving the same human-centered logic on modern RAP/Fiori architecture.

Why this rebuild exists

The original Resonance Leave was built in SAP ECC using SE11, SE24, SE38, and classic OO ABAP — a fully working burnout-radar and coverage-routing engine, inspired by watching my spouse, a contractor, work through exhaustion because no-work-no-pay terms leave no room for rest. That project proved the concept end to end: a system that detects who's struggling before they have to ask.

SAP itself is in the middle of a multi-year shift away from ECC. Mainstream maintenance for ECC 6.0 runs through the end of 2027, with the industry backlog of migrations still largely ahead of it. Rather than let the original project sit as ECC-only, I rebuilt it from scratch on RAP and Fiori Elements — the architecture SAP is actively moving customers toward — to prove the same design thinking translates to cloud-native ABAP, and to build hands-on experience with exactly the skill gap the market is short on: developers who understand both the classic and the RAP worlds.

What changed, and why

This isn't a line-by-line port — RAP has real architectural constraints that don't exist in classic ABAP, and working through them honestly is part of the story:

Four tables, rebuilt as RAP entities. ZRLV_EMP, ZRLV_BAL, ZRLV_REQ, ZRLV_ALLOC — same core structure as the ECC version, with CDS interface and projection views layered on top, and one deliberate schema addition: workload_pct on ZRLV_EMP, since RAP's association rules meant the old free-form "project workload allocation" table couldn't double as both a workload source and a coverage-assignment record. The two responsibilities got split cleanly instead.
The burnout algorithm, ported faithfully. The same dual-factor rule from ZCL_LEAVE_ENGINE: workload over 80% and balance under 5 days is CRITICAL; workload over 70% or balance under 10 days is ELEVATED; otherwise STABLE. In RAP this lives in a FOR DETERMINE ON SAVE method — workload is read through a managed association, balance is read via a direct SQL SELECT rather than an association, because RAP's managed-association rule requires matching every key field of the target entity, and the leave-year key on the balance table has no natural counterpart on the request table.
The 7-step submit method, reimplemented as one RAP action. The original SUBMIT_LEAVE_REQUEST validated dates, checked balance, ran the burnout radar, routed coverage, generated a UUID, inserted the request, and updated the balance — seven sequential steps in one method. In RAP, several of those steps are no longer manual: UUID generation is automatic for managed BOs with a sysuuid_x16 key, and the burnout radar runs on its own via the determination. What's left is a single submit action that validates status and balance, routes coverage to the lowest-workload same-skill-group colleague, creates the coverage allocation as a composition child, and decrements the balance — the balance write itself deferred to a custom saver class, since native SQL writes aren't permitted during RAP's interaction phase and must happen in the dedicated save phase instead.
Validation and authorization, done properly rather than skipped: date-range and quantity checks via VALIDATE ON SAVE, and an instance authorization rule that locks a request from further edits once it's been submitted.
A live Fiori List Report, generated from the RAP business object with zero custom UI code, using @UI.criticality to color-code each row by burnout risk. One subtlety worth noting: SAP's criticality scale (1=red, 2=yellow, 3=green) runs in the opposite direction from the app's own risk scale (1=stable, 3=critical) — a direct annotation would have shown a critical case in green. A small computed field in the CDS view translates between the two scales correctly.
What this demonstrates

Building the same idea twice, on two different generations of the same platform, surfaces the parts of the design that were actually sound versus the parts that were convenient shortcuts of the old architecture. The dual-factor burnout rule and the skill-group coverage routing survived the rebuild unchanged — they were good logic regardless of platform. What didn't survive unchanged were the mechanics: RAP's strict transactional contracts (no native SQL mid-transaction, explicit authorization handlers, managed-association key rules) forced more disciplined, more testable code than the original ever needed to be.

Repository structure
ZRESONANCE package (BTP ABAP Environment, package ZRESONANCE under ZLOCAL)
├── Dictionary
│   └── ZRLV_EMP, ZRLV_BAL, ZRLV_REQ, ZRLV_ALLOC
├── Core Data Services
│   ├── ZI_RESONANCE_EMPLOYEE, ZI_RESONANCE_BALANCE,
│   │   ZI_RESONANCE_REQUEST, ZI_RESONANCE_ALLOC   (interface views)
│   ├── ZC_RESONANCE_REQUEST                        (Fiori projection view)
│   └── Behavior Definitions for each RAP-enabled entity
├── Source Code Library
│   ├── ZBP_I_RESONANCE_REQUEST  (behavior pool: determination,
│   │   validation, submit action, authorization, saver class)
│   └── ZCL_RESONANCE_TEST_RUNNER (console test harness)
└── ZUI_RESONANCE_REQUEST / ZUI_RESONANCE_REQUEST_O4
    (service definition + OData V4 UI service binding)
Live apps

Both Fiori Elements apps are generated directly from the RAP business object — no custom UI code, just CDS annotations:

Leave Requests (List Report) — <img width="1906" height="478" alt="image" src="https://github.com/user-attachments/assets/724985e5-fa26-46a5-8315-f67bbf08588d" />

Employee Risk Dashboard <img width="1361" height="629" alt="image" src="https://github.com/user-attachments/assets/e66700c6-0d1b-49c1-bd80-21c99846ff2d" />


Both apps are also packaged as IAM Apps (ZIAM_RESONANCE_REQUEST_EXT, ZIAM_RESONANCE_RISK_DASH_EXT) under a shared Business Catalog (ZBC_RESONANCE_LEAVE), so in a production system they'd surface as launchpad tiles under one role assignment. Wiring that final role-collection step needs elevated BTP administrator access that isn't available on a trial account, so for this portfolio build the apps are accessed via their individual preview URLs — but the launchpad-side objects are built, activated, and ready to attach to a role the moment that access exists.

Project status
Step	Description	Status
1	Database tables	✓ Complete
2	CDS interface views + associations	✓ Complete
3	Burnout-risk determination (FOR DETERMINE ON SAVE)	✓ Complete, verified
4	Custom submit action (multi-step transaction)	✓ Complete, verified
5	Validation + instance authorization	✓ Complete, verified
6	Fiori List Report with @UI.criticality	✓ Complete, verified live
7	Documentation + final polish	✓ This README
Reflection

The original project's closing line was that the empathy was the specification — that the whole system existed because a real person was struggling and the software managing his employment saw nothing wrong. That's still true here. What's different this time is the platform: RAP's stricter contracts meant every shortcut had to be justified rather than assumed, and every piece of business logic had to prove itself against the framework's own rules before it was allowed to run. If the original project showed the idea works, this one shows the idea holds up — that the human problem behind it wasn't dependent on any one version of ABAP to matter.
Reflection

The original project's closing line was that the empathy was the specification — that the whole system existed because a real person was struggling and the software managing his employment saw nothing wrong. That's still true here. What's different this time is the platform: RAP's stricter contracts meant every shortcut had to be justified rather than assumed, and every piece of business logic had to prove itself against the framework's own rules before it was allowed to run. If the original project showed the idea works, this one shows the idea holds up — that the human problem behind it wasn't dependent on any one version of ABAP to matter.
