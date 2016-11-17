# Overview of User Model

There are a number of different user types defined in ADRL,
corresponding to different levels of access required and allowed:

- The public ({AdminPolicy::PUBLIC_GROUP})

- Members of the public, _while on campus_ ({AdminPolicy::PUBLIC_CAMPUS_GROUP})

- Students, faculty and staff of the UC system ({AdminPolicy::UC_GROUP})

- Students, faculty and staff of UCSB ({AdminPolicy::UCSB_GROUP})

- Rights administrators ({AdminPolicy::RIGHTS_ADMIN})

- Metadata administrators ({AdminPolicy::META_ADMIN})

The same user may be a rights administrator and a metadata
administrator.

<table>
<thead>
<tr class="header">
<th style="text-align: left;">Group name</th>
<th style="text-align: left;">Source</th>
<th style="text-align: left;">Edit rights</th>
<th style="text-align: left;">View embargoed content</th>
<th style="text-align: left;">Edit object metadata</th>
<th style="text-align: left;">Edit collection metadata</th>
<th style="text-align: left;">Manage local authorities</th>
<th style="text-align: left;">Create bookmarks</th>
<th style="text-align: left;">Download unembargoed MIL master files</th>
<th style="text-align: left;">Download unembargoed SRC master files</th>
<th style="text-align: left;">Edit about pages</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;"><code>PUBLIC_GROUP</code></td>
<td style="text-align: left;">n/a</td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>PUBLIC_CAMPUS_GROUPS</code></td>
<td style="text-align: left;">Campus IP</td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>UC_GROUP</code></td>
<td style="text-align: left;">Shibboleth</td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
<td style="text-align: left;">x</td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>UCSB_GROUP</code></td>
<td style="text-align: left;">Campus LDAP</td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
<td style="text-align: left;">x</td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>MIL_STAFF</code></td>
<td style="text-align: left;">Active Directory</td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
<td style="text-align: left;">x</td>
<td style="text-align: left;">x</td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>SRC_STAFF</code></td>
<td style="text-align: left;">Active Directory</td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
<td style="text-align: left;">x</td>
<td style="text-align: left;"></td>
<td style="text-align: left;">x</td>
<td style="text-align: left;"></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>RIGHTS_ADMIN</code></td>
<td style="text-align: left;">Active Directory</td>
<td style="text-align: left;">x</td>
<td style="text-align: left;">x</td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
<td style="text-align: left;">x</td>
<td style="text-align: left;">x</td>
<td style="text-align: left;">x</td>
<td style="text-align: left;"></td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>METADATA_ADMIN</code></td>
<td style="text-align: left;">Active Directory</td>
<td style="text-align: left;"></td>
<td style="text-align: left;"></td>
<td style="text-align: left;">x</td>
<td style="text-align: left;">x</td>
<td style="text-align: left;">x</td>
<td style="text-align: left;">x</td>
<td style="text-align: left;">x</td>
<td style="text-align: left;">x</td>
<td style="text-align: left;"></td>
</tr>
</tbody>
</table>

# Implementation

Whether a user is a UC member, UCSB member, rights admin, or metadata
admin is determined by the LDAP groups they belong to.  Accordingly
these classifications can only be assigned to users that have logged
in.

Users that aren’t logged in are automatically assigned to
{AdminPolicy::PUBLIC_GROUP}.  If the IP address they are connecting
from is a campus IP address (determined by
{ApplicationController#on_campus?}), they are added to
{AdminPolicy::PUBLIC_CAMPUS_GROUP} and given the appropriate level of
access.  Likewise, members of UCSB connecting from a campus IP address
are added to {AdminPolicy::UCSB_CAMPUS_GROUP}.  This dynamic
assignment occurs in {Ability#user_groups}—an “ability” is initialized
for each user and contains information about what rights and access
they have.
