defmodule StridentWeb.Components.TermsOfUse do
  @moduledoc """
  Common terms of user component rendering the
  latest terms of use contract.
  """

  use Phoenix.Component

  def contract(assigns) do
    ~H"""
    <div>
      <p class="paragraph-P1"><span class="text-T1">TERMS OF USE</span> <span class="text-T1" /></p>

      <p class="paragraph-P1">Effective November 1, 2023</p>
      <p class="paragraph-P3"></p>
      <p class="paragraph-Standard">
        <span class="text-T2">TERMS OF USE</span> <span class="text-T2" />
      </p>

      <p class="paragraph-Standard">
        <span class="text-T2">OFFICIAL RULES</span> <span class="text-T2" />
      </p>
      <p class="paragraph-P2"></p>
      <p class="paragraph-Standard">NO PURCHASE NECESSARY TO ENTER OR WIN.</p>

      <p class="paragraph-Standard">
        BY PARTICIPATING IN THE STRIDE, INC. ESPORTS TOURNAMENTS (“COMPETITION”), EACH PARTICIPANT REPRESENTS AND WARRANTS THAT THEY MEET THE ELIGIBILITY REQUIREMENTS DETAILED WITHIN THESE OFFICIAL RULES AND ACKNOWLEDGES THAT FAILURE TO MEET ALL ELIGIBILITY REQUIREMENTS WILL RESULT IN DISQUALIFICATION. ENTRY CONSTITUTES YOUR ACCEPTANCE OF THESE OFFICIAL RULES. ALL ENTRIES AND REQUESTS BECOME THE PROPERTY OF STRIDE, INC. (THE “SPONSOR”) AND WILL NOT BE RETURNED OR ACKNOWLEDGED.
      </p>

      <p class="paragraph-Standard">
        Competitions are ongoing throughout the year. Consult the website for current dates and times for competitions and events and for competition entry period information.
      </p>

      <p class="paragraph-Standard">
        <span class="text-T2">ELIGIBILITY: </span>Competition is open to legal residents of the 50 United States or the District of Columbia that are enrolled in the competition and qualify for and win their respective tournament. Contestants must: (i) be age 13 or older at time of entry (“Entrant” or “You”), and (ii) if a minor, then have obtained a parent’s or legal guardian’s prior permission. Minors who enter must have the written consent of a parent or legal guardian in order to be eligible to receive any prizes. Employees of Sponsor and its respective parent company, subsidiaries, affiliates, advertising and promotion agencies, retailers, distributors (collectively, “Contest Entities”), and their immediate family members and/or those living in the same household of each are eligible to enter or win. Contest is subject to all applicable federal, state, and local laws and regulations. Void where prohibited by law. Sponsor’s decisions are final and binding on all matters.
      </p>

      <p class="paragraph-Standard">
        HOW TO ENTER: Participants must enroll in tournament, challenges, or events offered by the sponsor. During the respective tournament, challenges, or events, participates play (both in teams and individually). Winners of these tournaments are awarded prizes. All entries must be received during the Competition Entry Period. For the purposes of these Official Rules, receipt of an entry occurs when Sponsor’s server (or Website) records the timely submission or check-in for a match/tournament. Submission and check-in details are provided for each individual challenge, match/tournament, or event on the website. Any automated computer receipt (such as one confirming delivery of entry) does not constitute proof of actual receipt by Sponsor for purposes of these Official Rules. Entrants are subject to all notices posted on Website, including, but not limited to Sponsor’s privacy policy.
      </p>

      <p class="paragraph-Standard">
        Sponsor reserves the right to disqualify any entry for any reason, in its sole and absolute discretion.
      </p>

      <p class="paragraph-Standard">
        At the conclusion of the Competition, participants who have completed their respective tournament in 1st place, as determined by the judge and in conjunction with the rules established by the individual game publishers and posted within the competition rule book in their respective game, are deemed the winner.
      </p>

      <p class="paragraph-Standard">
        Judge’s decisions are final and binding. Only winners will be notified.
      </p>

      <p class="paragraph-Standard">
        TIES: In the event of further ties, the Judges will make the final determination as to which entry will win.
      </p>

      <p class="paragraph-Standard">
        The Sponsor reserves the right to not award a prize if, in its sole and absolute discretion, it does not receive a sufficient number of eligible and qualified entries or there is pending accusations of cheating in the competition.
      </p>

      <p class="paragraph-Standard">
        COMPETITION PRIZES &amp; CORRESPONDING APPROXIMATE RETAIL VALUES (“ARV”):
      </p>
      <p class="paragraph-Standard"></p>
      <p class="paragraph-Standard">
        Participants in sponsor’s competitions acknowledge that payouts for competition winnings may be issued using either Digital Gift card  / PayPal Payout / PayPal Payouts or PayPal, at the discretion of the sponsor. The specific method and provider will be determined by Sponsor based on tournament circumstances and participant location.
      </p>
      <p class="paragraph-Standard"></p>
      <p class="paragraph-Standard">
        Participants agree to provide accurate information for payouts and understand that the Sponsor is not responsible for issues with PayPal accounts or the redemption of Digital Gift card  / PayPal Payout / PayPal Payouts. By participating, participants accept these terms and conditions and any decisions made by Sponsor regarding payout methods.
      </p>
      <p class="paragraph-Standard"></p>
      <p class="paragraph-Standard">Minecraft Build Challenges:</p>

      <p class="paragraph-Standard">
        BEGINNER CATEGORY<span class="text-T3"> </span>1st place - $20 Digital Gift card / PayPal Payout / PayPal Payout<span class="text-T3"> </span>2nd place - $10 Digital Gift card / PayPal Payout / PayPal Payout
      </p>

      <p class="paragraph-Standard">
        ADVANCED / EXPERT CATEGORY<span class="text-T3"> </span>1st place - $40 Digital Gift card / PayPal Payout / PayPal Payout<span class="text-T3"> </span>2nd place - $20 Digital Gift card / PayPal Payout / PayPal Payout
      </p>

      <p class="paragraph-Standard">Minecraft Underwater Base Challenge:</p>

      <p class="paragraph-Standard">
        AGES 8 - 12 CATEGORY<span class="text-T3"> </span>1st place - $100 Digital Gift card / PayPal Payout / PayPal Payout<span class="text-T3"> </span>2nd place - $50 Digital Gift card / PayPal Payout / PayPal Payout
      </p>

      <p class="paragraph-Standard">
        AGES 13 - 18 CATEGORY<span class="text-T3"> </span>1st place - $100 Digital Gift card / PayPal Payout / PayPal Payout<span class="text-T3"> </span>2nd place - $50 Digital Gift card / PayPal Payout / PayPal Payout
      </p>

      <p class="paragraph-Standard">Rocket League Tournaments:</p>

      <p class="paragraph-Standard">
        1st place – Team Gift card / PayPal Payout valued at $225 (Gift card / PayPal Payouts of total value of $300 to be split and distributed by Sponsor evenly among registered team members if tournament is in teams)
      </p>

      <p class="paragraph-Standard">
        2nd place - Team Gift card / PayPal Payout valued at $150 (Gift card / PayPal Payouts of total value of $150 to be split and distributed by Sponsor evenly among registered team members if tournament is in teams)
      </p>

      <p class="paragraph-Standard">
        3rd place - Team Gift card / PayPal Payout valued at $75 (Gift card / PayPal Payouts of total value of $75 to be split and distributed by Sponsor evenly among registered team members if tournament is in teams)
      </p>

      <p class="paragraph-Standard">Fortnite Zero Build Tournament:</p>

      <p class="paragraph-Standard">
        1st Place – Gift card / PayPal Payout valued at $200 (Gift card / PayPal Payouts of total value of $200 to be split and distributed by Sponsor evenly among registered team members if tournament is in teams)
      </p>

      <p class="paragraph-Standard">
        2nd Place – Gift card / PayPal Payout valued at $100 (Gift card / PayPal Payouts of total value of $100 to be split and distributed by Sponsor evenly among registered team members if tournament is in teams)
      </p>

      <p class="paragraph-Standard">
        3rd Place – Gift card / PayPal Payout valued at $50 (Gift card / PayPal Payouts of total value of $50 to be split and distributed by Sponsor evenly among registered team members if tournament is in teams)
      </p>

      <p class="paragraph-Standard">Super Smash Bros Tournament:</p>

      <p class="paragraph-Standard">1st place –Gift card / PayPal Payout valued at $60</p>

      <p class="paragraph-Standard">2nd place - Gift card / PayPal Payout valued at $30</p>

      <p class="paragraph-Standard">3rd place - Gift card / PayPal Payout valued at $10</p>
      <p class="paragraph-Standard"></p>
      <p class="paragraph-Standard">
        WINNER NOTIFICATION: Potential winners will be notified by email, Discord DM or telephone, and/or US mail within 15 business days of the end of Competition Date, and may be required to complete and return a notarized Affidavit of Eligibility and Liability, a completed IRS Form W-9 and where permissible, a Publicity Release (“Affidavit/Release”), within seven days of date specified on notification, or an alternate winner may be determined. If an Affidavit/Release and/or if any required document(s) is not returned within such time period, or if a selected winner cannot accept or receive the prize for any reason, or if he or she is not in compliance with these Official Rules, the prize will be forfeited and an alternate winner may be determined. If a winner is otherwise eligible under these Official Rules, but is nevertheless deemed a minor in his or her state of primary residence, the prize will be awarded in the name of winner's parent or legal guardian who will be required to execute Affidavit/Release (or any required document) and submit a completed IRS Form W-9 on minor’s behalf. Prizes are awarded within 30 days after winner verification. Prizes are not redeemable for cash and are non-assignable or transferable except to a surviving spouse. No substitutions are permitted except the Sponsor reserves the right to substitute a prize, or portion of any prize, with one of equal or greater value in case of unavailability. Winners acknowledge that the Sponsor and all other businesses concerned with this Competition and their agents do not make, nor are in any manner responsible for any warranty, representations, expressed or implied, in fact or in law, relative to the quality, conditions, fitness, or merchantability of any aspect of any prize. Each winner will be responsible for all federal, state, local, and income taxes associated with winning his or her prize. Incidental expenses on any prize not specified herein are each winner’s sole responsibility, including all taxes. Except where prohibited by law, entry and acceptance of prize constitute permission for Sponsor and its agents to use each winner's name, prize won, hometown, likeness, photo and statements for purposes of advertising, trade, promotion, and publicity (including online posting) in any and all media now or hereafter known throughout the world in perpetuity, without additional compensation, notification or permission.
      </p>

      <p class="paragraph-Standard">
        CONDITIONS OF ENTRY: Entrants agree to these Official Rules and the decisions of the judges and the Sponsor, and on their behalf, and on behalf of their respective heirs, executors, administrators, legal representatives, successors, and assigns (“Releasing Parties”), release, defend, and hold harmless the Competition Entities, as well as the employees, officers, directors, and agents of each (“Released Parties”), from any and all actions, causes of action, suits, debts, dues, sums of money, accounts, reckonings, bonds, bills, specialties, covenants, contracts, controversies, agreements, promises, variances, trespasses, lost profits, indirect or direct damages, consequential damages, incidental damages, punitive or exemplary damages, judgments, extent, executions, claims and demands whatsoever, in law, admiralty or equity, whether known or unknown, foreseen or unforeseen, against Released Parties which any one or more of the Releasing Parties ever had, now have or hereafter can, shall or may have which in any way arise out of or result from Entrant’s participation, acceptance and use or misuse of any prize.
      </p>

      <p class="paragraph-Standard">
        In the event Sponsor is prevented from continuing with the Competition as planned herein by any event beyond its control, including but not limited to fire, flood, hurricane, earthquake, explosion, labor dispute or strike, act of God or public enemy, satellite or equipment failure, riot or civil disturbance, terrorist threat or activity, war (declared or undeclared) or any federal, state, or local government law, order, or regulation, or order of any court or other cause not within Sponsor’s control or concerns regarding the safety of any winner or guest, Sponsor shall have the right to modify, suspend, extend, or terminate the Competition. Entrants assume all liability for any injury, including death or damage caused or claimed to be caused, by participation in this Competition or use or redemption of any prize.
      </p>

      <p class="paragraph-Standard">
        This Competition shall be governed by and interpreted under the laws of the Commonwealth of Virginia, U.S. without regard to its conflicts of laws provisions. Entrants hereby agree that any and all disputes, claims, causes of action, or controversies (“Claims”) arising out of, or in connection with, this Competition shall be resolved, upon the election by Entrant or Sponsor, by arbitration pursuant to this provision and the code of procedures of either the National Arbitration Forum (“NAF”) or the American Arbitration Association (“AAA”), as selected by the Entrant. IF ARBITRATION IS CHOSEN BY ANY PARTY WITH RESPECT TO A CLAIM, NEITHER PARTY WILL HAVE THE RIGHT TO LITIGATE THAT CLAIM IN COURT OR HAVE A JURY TRIAL ON THAT CLAIM. FURTHER, NEITHER SPONSOR NOR ENTRANT WILL HAVE THE RIGHT TO PARTICIPATE IN A REPRESENTATIVE CAPACITY ON BEHALF OF THE GENERAL PUBLIC OR OTHER PERSONS SIMILARLY SITUATED, OR AS A MEMBER OF ANY CLASS OF CLAIMANTS PERTAINING TO ANY CLAIM SUBJECT TO ARBITRATION. EXCEPT AS SET FORTH BELOW, THE ARBITRATOR’S DECISION WILL BE FINAL AND BINDING. NOTE THAT OTHER RIGHTS THAT ENTRANT WOULD HAVE IF ENTRANT WENT TO COURT ALSO MAY NOT BE AVAILABLE IN ARBITRATION. The arbitrator’s authority to resolve Claims is limited to Claims between Sponsor and Entrant alone, and the arbitrator’s authority to make awards is limited to awards to Sponsor and Entrant alone. Furthermore, Claims brought by either party against the other may not be joined or consolidated in arbitration with Claims brought by or against any third party, unless agreed to in writing by all parties. No arbitration award or decision will have any preclusive effect as to issues or claims in any dispute with anyone who is not a named party to the arbitration. Notwithstanding any other provision in this Agreement, and without waiving either party’s right to appeal such decision, should any portion of this provision be deemed invalid or unenforceable, then the entire provision (other than this sentence) shall not apply. Sponsor is not responsible for any typographical or other error in the printing of the offer, administration of the Competition, or in the announcement of any prize.
      </p>

      <p class="paragraph-Standard">
        Sponsor and Entrant agree that an arbitration award (“Underlying Award”) may be appealed pursuant to the American Arbitration Association’s Optional Appellate Arbitration Rules (“Appellate Rules”); that any the Underlying Award shall, at a minimum, be a reasoned award, and that the Underlying Award shall not be considered final until after the time for filing a notice of appeal pursuant to the Appellate Rules has expired. Appeals must be initiated within 30 days of receipt of an Underlying Award, as defined by Rule A-3 of the Appellate Rules, by filing a Notice of Appeal with any office of the American Arbitration Association.
      </p>

      <p class="paragraph-Standard">
        LIMITATIONS OF LIABILITY FOR WEB ACCESS: The Sponsor is not responsible for any incorrect or inaccurate information, whether caused by Website users, or tampering or hacking, or by any of the equipment or programming associated with or utilized in the Competition, and assumes no responsibility for any error, omission, interruption, deletion, defect, delay in operation or transmission, communications line failure, theft or destruction, or unauthorized access to the Website. The Sponsor is not responsible for injury or damage to an Entrant’s or to any other person’s computer related to or resulting from participating in this Competition or downloading and/or uploading materials from or use of the Website. If for any reason, the Competition is not capable of running as planned by reason of infection by computer virus, worms, bugs, tampering, unauthorized intervention, fraud, technical failures, or any other causes which, in the sole opinion of the Sponsor could corrupt or affect the administration, security, fairness, integrity, or proper conduct of this Competition, the Sponsor reserves the right at its sole discretion to cancel, terminate, modify, or suspend the Competition and determine winners from all eligible entries received prior to that action taken.
      </p>

      <p class="paragraph-Standard">
        Entry materials/data that have been tampered with or altered, or mass entries or entries generated by a script, macro or use of automated devices are void. Entries made with multiple email addresses, under multiple identities, or through the use of any automated other device or artifice to enter multiple times will be deemed invalid. Mechanically reproduced, illegible, incomplete, or inaccurate entries are void. In the event of a dispute, entries (including photos, photos, and/or essays) will be deemed to have been submitted by the Authorized Account Holder of the email address provided at the time of entry. “Authorized Account Holder” means the natural person who is assigned to an email address by an internet access provider, online service provider, or other organization that is responsible for assigning email addresses for the domain associated with the submitted email address. Mechanically reproduced entries are not eligible. Sponsor is not responsible for lost, late, damaged, or misdirected entries.
      </p>

      <p class="paragraph-Standard">
        OPT-IN/OPT-OUT: By entering the Competition, Entrants agree that collected information from Entrants may be used for future communications (via U.S. mail, phone, text or email) by Sponsor regarding its products and services including current offers and promotions, in addition to being used to notify winners. Refer to the Sponsor’s privacy policy at https://www.stridelearning.com/privacy-policy.html to learn how to opt-out if you do not wish to receive future offers from Sponsor.
      </p>
      <p class="paragraph-Standard"></p>
    </div>
    """
  end

  def tournament_registration_terms(assigns) do
    ~H"""
    <div>
      <p>
        By participating in the stride, inc. Esports tournaments (“competition”), each participant represents and warrants that they meet the eligibility requirements detailed within these official rules and acknowledges that failure to meet all eligibility requirements will result in disqualification. Entry constitutes your acceptance of these official rules. All entries and requests become the property of stride, inc. (the “sponsor”) and will not be returned or acknowledged.
      </p>

      <p>
        Competitions are ongoing throughout the year. Consult the website for current dates and times for competitions and events and for competition entry period information.
      </p>

      <p>
        ELIGIBILITY: Competition is open to legal residents of the 50 United States or the District of Columbia that are enrolled in the competition and qualify for and win their respective tournament. Contestants must: (i) be age 13 or older at time of entry (“Entrant” or “You”), and (ii) if a minor, then have obtained a parent’s or legal guardian’s prior permission. Minors who enter must have the written consent of a parent or legal guardian in order to be eligible to receive any prizes. Employees of Sponsor and its respective parent company, subsidiaries, affiliates, advertising and promotion agencies, retailers, distributors (collectively, “Contest Entities”), and their immediate family members and/or those living in the same household of each are eligible to enter or win. Contest is subject to all applicable federal, state, and local laws and regulations. Void where prohibited by law. Sponsor’s decisions are final and binding on all matters.
      </p>

      <p>
        HOW TO ENTER: Participants must enroll in tournament, challenges, or events offered by the sponsor. During the respective tournament, challenges, or events, participates play (both in teams and individually). Winners of these tournaments are awarded prizes. All entries must be received during the Competition Entry Period. For the purposes of these Official Rules, receipt of an entry occurs when Sponsor’s server (or Website) records the timely submission or check-in for a match/tournament. Submission and check-in details are provided for each individual challenge, match/tournament, or event on the website. Any automated computer receipt (such as one confirming delivery of entry) does not constitute proof of actual receipt by Sponsor for purposes of these Official Rules. Entrants are subject to all notices posted on Website, including, but not limited to Sponsor’s privacy policy.
      </p>

      <p>
        Sponsor reserves the right to disqualify any entry for any reason, in its sole and absolute discretion.
      </p>

      <p>
        At the conclusion of the Competition, participants who have completed their respective tournament in 1st place, as determined by the judge and in conjunction with the rules established by the individual game publishers and posted within the competition rule book in their respective game, are deemed the winner.
      </p>

      <p>
        Judge’s decisions are final and binding. Only winners will be notified.
      </p>

      <p>
        TIES: In the event of further ties, the Judges will make the final determination as to which entry will win.
      </p>

      <p>
        The Sponsor reserves the right to not award a prize if, in its sole and absolute discretion, it does not receive a sufficient number of eligible and qualified entries or there is pending accusations of cheating in the competition.
      </p>

      <p>
        Prize Restricted Regions
      </p>

      <p>
        Notwithstanding The Foregoing Or Any Other Provision Of These Rules To The Contrary, If You Are An Individual Residing In
      </p>

      <p>
        Cuba, North Korea, Syria, Iran, Afghanistan, Burma, Iraq
      </p>

      <p>
        (Each, A “Prize Restricted Region”), You Acknowledge And Agree (And If A Minor, Your Parent Or Legal Guardian Acknowledges And Agrees) That You Are Not Eligible For Nor Entitled To Win Any Prizes In Connection With The Event.
      </p>

      <p>
        Additionally, if you reside in the restricted jurisdiction (list of countries mentioned below) a sanction search will be made before issuing your prize
      </p>

      <p>
        Belarus, Central African Republic, China, Ethiopia, Democratic Republic of Congo, Hong Kong, Lebanon, Libya, Nicaragua, Russia, Somalia, South Sudan, Ukraine, Venezuela, Western Balkans (o Bosnia and Herzegovina, Montenegro, Albania, Kosovo, North Macedonia, Serbia) , Yemen, Zimbabwe
      </p>

      <p>
        If your name appears to be on the Sanction list found at https://ofac.treasury.gov/specially-designated-nationals-and-blocked-persons-list-sdn-human-readable-lists then the prize will not be issued by the sponsor
      </p>

      <p>
        Only the highest scoring players who do not otherwise reside in a Prize Restricted Region (as determined by above) will be eligible to receive the applicable prizes set forth in the competition details page (“Winning Players”). No other player with a score lower than the Winning Players or residing in a Prize Restricted Region shall be, at any time or under any circumstances, entitled to win any prizes in connection with the Event.
      </p>

      <p>
        For clarity, prizes are awarded “as is” with no warranty or guarantee, either express or implied. Prizes are not transferable or assignable and cannot be transferred by Winning Players. Non-cash prizes (if any) cannot be redeemed for cash. All prize details are at the sole discretion of Sponsor. Winning Players are not entitled to any surplus between actual retail value of prize and approximate retail value and any difference between approximate and actual value of the prize will not be awarded. Winning Players are responsible for any costs and expenses associated with prize acceptance and use not specified herein as being provided. Winning Players may not substitute a prize, but Sponsor reserves the right, at its sole discretion, in case of justified reasons, to substitute a prize (or portion thereof) with one of comparable or greater value. Additional terms and conditions may apply to acceptance and use of a prize.
      </p>
    </div>
    """
  end
end
